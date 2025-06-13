using Microsoft.Extensions.Logging;
using System.Text.Json;

namespace Remotely.Desktop.Shared.Services;

public interface IAutoConnectConfig
{
    bool IsAutoConnectEnabled { get; }
    string ServerUrl { get; }
    string DeviceName { get; }
    bool HideSessionId { get; }
    bool MinimizeToTray { get; }
    int ConnectionTimeout { get; }
    int RetryAttempts { get; }
    int RetryDelay { get; }
    Task<bool> TryAutoConnectAsync();
}

public class AutoConnectConfig : IAutoConnectConfig
{
    private readonly ILogger<AutoConnectConfig> _logger;
    private readonly IAppState _appState;

    // Built-in configuration - modify these values for your setup
    private const string DEFAULT_SERVER_URL = "http://192.168.1.32:5001";
    private const string DEFAULT_DEVICE_NAME = "AI-Exam-Client";
    private const bool DEFAULT_AUTO_CONNECT = true;
    private const bool DEFAULT_HIDE_SESSION_ID = true;
    private const bool DEFAULT_MINIMIZE_TO_TRAY = true;
    private const int DEFAULT_CONNECTION_TIMEOUT = 30000;
    private const int DEFAULT_RETRY_ATTEMPTS = 5;
    private const int DEFAULT_RETRY_DELAY = 3000;

    public AutoConnectConfig(ILogger<AutoConnectConfig> logger, IAppState appState)
    {
        _logger = logger;
        _appState = appState;
    }

    public bool IsAutoConnectEnabled => DEFAULT_AUTO_CONNECT;
    public string ServerUrl => DEFAULT_SERVER_URL;
    public string DeviceName => DEFAULT_DEVICE_NAME;
    public bool HideSessionId => DEFAULT_HIDE_SESSION_ID;
    public bool MinimizeToTray => DEFAULT_MINIMIZE_TO_TRAY;
    public int ConnectionTimeout => DEFAULT_CONNECTION_TIMEOUT;
    public int RetryAttempts => DEFAULT_RETRY_ATTEMPTS;
    public int RetryDelay => DEFAULT_RETRY_DELAY;

    public async Task<bool> TryAutoConnectAsync()
    {
        if (!IsAutoConnectEnabled)
        {
            _logger.LogInformation("Auto-connect is disabled");
            return false;
        }

        _logger.LogInformation("Starting auto-connect to {ServerUrl}", ServerUrl);

        try
        {
            // Check if server URL is already set
            if (string.IsNullOrEmpty(_appState.Host))
            {
                _logger.LogInformation("Setting server URL to {ServerUrl}", ServerUrl);
                _appState.Host = ServerUrl;
            }

            // Enable auto-accept for AI Exam clients
            _appState.AutoAcceptConnections = true;
            _logger.LogInformation("Auto-accept enabled for AI Exam client");

            // Test connectivity to server
            using var httpClient = new HttpClient();
            httpClient.Timeout = TimeSpan.FromMilliseconds(ConnectionTimeout);

            var response = await httpClient.GetAsync($"{ServerUrl}/api/health");
            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("Successfully connected to server at {ServerUrl}", ServerUrl);
                return true;
            }
            else
            {
                _logger.LogWarning("Server responded with status {StatusCode}", response.StatusCode);
                return false;
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to auto-connect to {ServerUrl}", ServerUrl);
            return false;
        }
    }

    /// <summary>
    /// Load configuration from external file if it exists, otherwise use built-in defaults
    /// </summary>
    public static AutoConnectSettings LoadConfiguration()
    {
        var configPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "autoconnect.json");
        
        if (File.Exists(configPath))
        {
            try
            {
                var json = File.ReadAllText(configPath);
                var config = JsonSerializer.Deserialize<AutoConnectSettings>(json);
                if (config != null)
                {
                    return config;
                }
            }
            catch (Exception)
            {
                // Fall back to defaults if config file is invalid
            }
        }

        // Return built-in defaults
        return new AutoConnectSettings
        {
            ServerUrl = DEFAULT_SERVER_URL,
            DeviceName = DEFAULT_DEVICE_NAME,
            AutoConnect = DEFAULT_AUTO_CONNECT,
            HideSessionId = DEFAULT_HIDE_SESSION_ID,
            MinimizeToTray = DEFAULT_MINIMIZE_TO_TRAY,
            ConnectionTimeout = DEFAULT_CONNECTION_TIMEOUT,
            RetryAttempts = DEFAULT_RETRY_ATTEMPTS,
            RetryDelay = DEFAULT_RETRY_DELAY
        };
    }
}

public class AutoConnectSettings
{
    public string ServerUrl { get; set; } = string.Empty;
    public string DeviceName { get; set; } = string.Empty;
    public bool AutoConnect { get; set; }
    public bool HideSessionId { get; set; }
    public bool MinimizeToTray { get; set; }
    public int ConnectionTimeout { get; set; }
    public int RetryAttempts { get; set; }
    public int RetryDelay { get; set; }
} 