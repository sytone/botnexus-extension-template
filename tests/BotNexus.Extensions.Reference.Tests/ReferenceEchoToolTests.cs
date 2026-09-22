using System.Text.Json;
using BotNexus.Agent.Core.Types;
using Xunit;

namespace BotNexus.Extensions.Reference.Tests;

public sealed class ReferenceEchoToolTests
{
    [Fact]
    public async Task ExecuteAsync_EchoesText()
    {
        var tool = new ReferenceEchoTool();
        var arguments = await tool.PrepareArgumentsAsync(new Dictionary<string, object?>
        {
            ["text"] = "hello BotNexus"
        });

        var result = await tool.ExecuteAsync("call-1", arguments);

        Assert.Single(result.Content);
        Assert.Equal(AgentToolContentType.Text, result.Content[0].Type);
        Assert.Equal("hello BotNexus", result.Content[0].Value);
    }

    [Fact]
    public async Task ExecuteAsync_AcceptsJsonArgumentsAndUppercases()
    {
        var tool = new ReferenceEchoTool();
        using var document = JsonDocument.Parse("""{"text":"hello","uppercase":true}""");
        var arguments = document.RootElement.EnumerateObject()
            .ToDictionary(property => property.Name, property => (object?)property.Value.Clone());
        var prepared = await tool.PrepareArgumentsAsync(arguments);

        var result = await tool.ExecuteAsync("call-2", prepared);

        Assert.Equal("HELLO", result.Content[0].Value);
    }

    [Fact]
    public async Task PrepareArgumentsAsync_RejectsBlankText()
    {
        var tool = new ReferenceEchoTool();

        var error = await Assert.ThrowsAsync<ArgumentException>(() =>
            tool.PrepareArgumentsAsync(new Dictionary<string, object?> { ["text"] = " " }));

        Assert.Contains("must not be blank", error.Message, StringComparison.Ordinal);
    }

    [Fact]
    public void Definition_MatchesToolNameAndRequiresText()
    {
        var tool = new ReferenceEchoTool();

        Assert.Equal(tool.Name, tool.Definition.Name);
        var required = tool.Definition.Parameters.GetProperty("required");
        Assert.Contains(required.EnumerateArray(), value => value.GetString() == "text");
    }
}
