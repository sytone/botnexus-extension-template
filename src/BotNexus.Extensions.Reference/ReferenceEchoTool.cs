using System.Text.Json;
using BotNexus.Agent.Core.Tools;
using BotNexus.Agent.Core.Types;
using BotNexus.Agent.Providers.Core.Models;

namespace BotNexus.Extensions.Reference;

/// <summary>A small deterministic tool that demonstrates the complete extension contract.</summary>
public sealed class ReferenceEchoTool : IAgentTool
{
    public string Name => "reference_echo";

    public string Label => "Reference Echo";

    public string ContentSource => ToolContentSource.Local;

    public Tool Definition { get; } = new(
        "reference_echo",
        "Echo text from the reference BotNexus extension. Use this to verify that an out-of-tree extension loaded correctly.",
        JsonDocument.Parse("""
            {
              "type": "object",
              "properties": {
                "text": {
                  "type": "string",
                  "description": "Text to echo."
                },
                "uppercase": {
                  "type": "boolean",
                  "description": "Return the text in uppercase when true. Default: false."
                }
              },
              "required": ["text"],
              "additionalProperties": false
            }
            """).RootElement.Clone());

    public Task<IReadOnlyDictionary<string, object?>> PrepareArgumentsAsync(
        IReadOnlyDictionary<string, object?> arguments,
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();

        if (!arguments.TryGetValue("text", out var value) || string.IsNullOrWhiteSpace(ReadString(value)))
            throw new ArgumentException("text is required and must not be blank.", nameof(arguments));

        return Task.FromResult<IReadOnlyDictionary<string, object?>>(
            new Dictionary<string, object?>(arguments, StringComparer.OrdinalIgnoreCase));
    }

    public Task<AgentToolResult> ExecuteAsync(
        string toolCallId,
        IReadOnlyDictionary<string, object?> arguments,
        CancellationToken cancellationToken = default,
        AgentToolUpdateCallback? onUpdate = null)
    {
        cancellationToken.ThrowIfCancellationRequested();

        var text = ReadString(arguments["text"])
            ?? throw new ArgumentException("text is required.", nameof(arguments));
        var uppercase = arguments.TryGetValue("uppercase", out var rawUppercase) && ReadBoolean(rawUppercase);
        var output = uppercase ? text.ToUpperInvariant() : text;

        return Task.FromResult(new AgentToolResult(
            [new AgentToolContent(AgentToolContentType.Text, output)],
            Details: new { toolCallId, uppercase }));
    }

    public string? GetPromptSnippet() => "Use reference_echo to verify the reference extension is installed.";

    private static string? ReadString(object? value) => value switch
    {
        string text => text,
        JsonElement { ValueKind: JsonValueKind.String } element => element.GetString(),
        _ => value?.ToString()
    };

    private static bool ReadBoolean(object? value) => value switch
    {
        bool boolean => boolean,
        JsonElement { ValueKind: JsonValueKind.True } => true,
        JsonElement { ValueKind: JsonValueKind.False } => false,
        string text when bool.TryParse(text, out var parsed) => parsed,
        _ => false
    };
}
