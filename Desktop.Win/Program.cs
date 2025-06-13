using Avalonia;
using Remotely.Desktop.Shared.Services;
using Remotely.Desktop.Shared.Startup;
using Remotely.Desktop.UI;
using Remotely.Desktop.UI.Services;
using Microsoft.Extensions.DependencyInjection;
using Remotely.Desktop.Win.Startup;
using Remotely.Shared.Services;
using Remotely.Shared.Utilities;
using System.Diagnostics;
using System.Runtime.Versioning;
using Remotely.Desktop.UI.Startup;

namespace Remotely.Desktop.Win;

public class Program
{
    // This is needed for the visual designer to work.
    public static AppBuilder BuildAvaloniaApp()
        => AppBuilder.Configure<App>()
            .UsePlatformDetect()
            .WithInterFont()
            .LogToTrace();


    [SupportedOSPlatform("windows")]
    public static async Task Main(string[] args)
    {
        var version = AppVersionHelper.GetAppVersion();
        var logger = new FileLogger("Remotely_Desktop", version, "Program.cs");
        var filePath = Environment.ProcessPath ?? Environment.GetCommandLineArgs().First();
        var serverUrl = Debugger.IsAttached ? "https://localhost:5001" : string.Empty;
        var getEmbeddedResult =  EmbeddedServerDataProvider.Instance.TryGetEmbeddedData(filePath);
        if (getEmbeddedResult.IsSuccess)
        {
            serverUrl = getEmbeddedResult.Value.ServerUrl.AbsoluteUri;
        }
        else
        {
            logger.LogWarning(getEmbeddedResult.Exception, "Failed to extract embedded server data.");
        }
        var services = new ServiceCollection();

        services.AddSingleton<IEmbeddedServerDataProvider>(EmbeddedServerDataProvider.Instance);

        services.AddRemoteControlXplat();
        services.AddRemoteControlUi();
        services.AddRemoteControlWindows();

        services.AddLogging(builder =>
        {
            if (EnvironmentHelper.IsDebug)
            {
                builder.SetMinimumLevel(LogLevel.Debug);
            }
            builder.AddProvider(new FileLoggerProvider("Remotely_Desktop", version));
        });

        var provider = services.BuildServiceProvider();

        var appState = provider.GetRequiredService<IAppState>();
        var autoConnectConfig = provider.GetRequiredService<IAutoConnectConfig>();

        // Try auto-connect first
        if (autoConnectConfig.IsAutoConnectEnabled)
        {
            logger.LogInformation("Auto-connect is enabled. Attempting to connect to {ServerUrl}", autoConnectConfig.ServerUrl);
            var autoConnectSuccess = await autoConnectConfig.TryAutoConnectAsync();
            
            if (autoConnectSuccess)
            {
                logger.LogInformation("Auto-connect successful");
                serverUrl = autoConnectConfig.ServerUrl;
            }
            else
            {
                logger.LogWarning("Auto-connect failed, falling back to embedded/manual configuration");
            }
        }

        if (getEmbeddedResult.IsSuccess)
        {
            appState.OrganizationId = getEmbeddedResult.Value.OrganizationId;
            // Only override if auto-connect didn't work
            if (string.IsNullOrEmpty(appState.Host))
            {
                appState.Host = getEmbeddedResult.Value.ServerUrl.AbsoluteUri;
            }
        }

        if (appState.ArgDict.TryGetValue("org-id", out var orgId))
        {
            appState.OrganizationId = orgId;
        }

        var result = await provider.UseRemoteControlClient(
            args,
            "The remote control client for Remotely.",
            serverUrl,
            false);

        if (!result.IsSuccess)
        {
            logger.LogError(result.Exception, "Failed to start remote control client.");
            Environment.Exit(1);
        }

        var dispatcher = provider.GetRequiredService<IUiDispatcher>();

        try
        {
            await Task.Delay(Timeout.InfiniteTimeSpan, dispatcher.ApplicationExitingToken);
        }
        catch (OperationCanceledException) { }

        // Output type is WinExe, so we need to explicitly exit.
        Environment.Exit(0);
    }
}