using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;

namespace Chillax.Notification.API.Services;

public class FcmService : IFcmService
{
    private const string FirebaseCredentialsFileName = "firebase-credentials.json";
    private readonly ILogger<FcmService> _logger;
    private readonly bool _isInitialized;

    public FcmService(ILogger<FcmService> logger)
    {
        _logger = logger;

        try
        {
            if (FirebaseApp.DefaultInstance == null)
            {
                var credentialsPath = FindCredentialsFile();

                if (credentialsPath != null)
                {
                    FirebaseApp.Create(new AppOptions
                    {
                        Credential = GoogleCredential.FromFile(credentialsPath)
                    });
                    _isInitialized = true;
                    _logger.LogInformation("Firebase initialized successfully from {Path}", credentialsPath);
                }
                else
                {
                    _logger.LogWarning("{FileName} not found. FCM notifications will be simulated.", FirebaseCredentialsFileName);
                    _isInitialized = false;
                }
            }
            else
            {
                _isInitialized = true;
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to initialize Firebase");
            _isInitialized = false;
        }
    }

    private string? FindCredentialsFile()
    {
        // Check current directory
        var currentDir = Path.Combine(Directory.GetCurrentDirectory(), FirebaseCredentialsFileName);
        if (File.Exists(currentDir))
            return currentDir;

        // Check app base directory
        var baseDir = Path.Combine(AppContext.BaseDirectory, FirebaseCredentialsFileName);
        if (File.Exists(baseDir))
            return baseDir;

        return null;
    }

    public async Task<bool> SendNotificationAsync(string fcmToken, string title, string body, Dictionary<string, string>? data = null)
    {
        if (!_isInitialized)
        {
            _logger.LogInformation("Simulating FCM notification to token {Token}: {Title} - {Body}",
                fcmToken[..Math.Min(10, fcmToken.Length)] + "...", title, body);
            return true;
        }

        try
        {
            var message = new Message
            {
                Token = fcmToken,
                Notification = new FirebaseAdmin.Messaging.Notification
                {
                    Title = title,
                    Body = body
                },
                Data = data
            };

            var response = await FirebaseMessaging.DefaultInstance.SendAsync(message);
            _logger.LogInformation("FCM notification sent successfully: {Response}", response);
            return true;
        }
        catch (FirebaseMessagingException ex) when (ex.MessagingErrorCode == MessagingErrorCode.Unregistered)
        {
            _logger.LogWarning("FCM token is no longer valid: {Token}", fcmToken[..Math.Min(10, fcmToken.Length)] + "...");
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send FCM notification to token {Token}", fcmToken[..Math.Min(10, fcmToken.Length)] + "...");
            return false;
        }
    }

    public async Task<int> SendBatchNotificationsAsync(IEnumerable<string> fcmTokens, string title, string body, Dictionary<string, string>? data = null)
    {
        var tokenList = fcmTokens.ToList();
        if (tokenList.Count == 0)
        {
            return 0;
        }

        if (!_isInitialized)
        {
            _logger.LogInformation("Simulating batch FCM notifications to {Count} tokens: {Title} - {Body}",
                tokenList.Count, title, body);
            return tokenList.Count;
        }

        try
        {
            var messages = tokenList.Select(token => new Message
            {
                Token = token,
                Notification = new FirebaseAdmin.Messaging.Notification
                {
                    Title = title,
                    Body = body
                },
                Data = data
            }).ToList();

            var response = await FirebaseMessaging.DefaultInstance.SendEachAsync(messages);
            _logger.LogInformation("Batch FCM notifications sent: {Success}/{Total} successful",
                response.SuccessCount, tokenList.Count);
            return response.SuccessCount;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send batch FCM notifications");
            return 0;
        }
    }
}
