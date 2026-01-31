using System.Reflection;

namespace Microsoft.Extensions.Hosting;

internal static class HostEnvironmentExtensions
{
    public static bool IsBuild(this IHostEnvironment hostEnvironment)
    {
        return hostEnvironment.IsEnvironment("Build") || Assembly.GetEntryAssembly()?.GetName().Name == "GetDocument.Insider";
    }
}
