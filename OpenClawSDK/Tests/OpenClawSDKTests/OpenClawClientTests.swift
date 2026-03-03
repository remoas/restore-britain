import XCTest
@testable import OpenClawSDK

final class OpenClawClientTests: XCTestCase {

    func testClientInitialization() {
        let url = URL(string: "http://localhost:18789")!
        let client = OpenClawClient(gatewayURL: url, token: "test-token")

        XCTAssertEqual(client.gatewayURL, url)
    }

    func testChatMessageEncoding() throws {
        let message = ChatMessage(role: .user, content: "Hello Larry")
        let data = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(ChatMessage.self, from: data)

        XCTAssertEqual(decoded.role, .user)
        XCTAssertEqual(decoded.content, "Hello Larry")
    }

    func testChatMessageRoles() {
        XCTAssertEqual(Role.system.rawValue, "system")
        XCTAssertEqual(Role.user.rawValue, "user")
        XCTAssertEqual(Role.assistant.rawValue, "assistant")
    }

    func testAgentSessionCreation() {
        let url = URL(string: "http://localhost:18789")!
        let client = OpenClawClient(gatewayURL: url, token: "test-token")
        let session = AgentSession(client: client, agentId: "larry-agent")

        XCTAssertEqual(session.agentId, "larry-agent")
        XCTAssertTrue(session.history.isEmpty)
    }

    func testAgentSessionWithSystemPrompt() {
        let url = URL(string: "http://localhost:18789")!
        let client = OpenClawClient(gatewayURL: url, token: "test-token")
        let session = AgentSession(
            client: client,
            agentId: "larry-agent",
            systemPrompt: "You are Larry."
        )

        XCTAssertEqual(session.history.count, 1)
        XCTAssertEqual(session.history.first?.role, .system)
        XCTAssertEqual(session.history.first?.content, "You are Larry.")
    }

    func testAgentSessionReset() {
        let url = URL(string: "http://localhost:18789")!
        let client = OpenClawClient(gatewayURL: url, token: "test-token")
        let session = AgentSession(
            client: client,
            agentId: "larry-agent",
            systemPrompt: "You are Larry."
        )

        // Reset keeping system prompt
        session.reset(keepSystemPrompt: true)
        XCTAssertEqual(session.history.count, 1)
        XCTAssertEqual(session.history.first?.role, .system)

        // Reset clearing everything
        session.reset(keepSystemPrompt: false)
        XCTAssertTrue(session.history.isEmpty)
    }

    func testErrorDescriptions() {
        XCTAssertNotNil(OpenClawSDKError.unauthorized.errorDescription)
        XCTAssertNotNil(OpenClawSDKError.endpointNotEnabled.errorDescription)
        XCTAssertNotNil(OpenClawSDKError.rateLimited.errorDescription)
        XCTAssertNotNil(OpenClawSDKError.httpError(statusCode: 500).errorDescription)
        XCTAssertNotNil(OpenClawSDKError.invalidResponse.errorDescription)
        XCTAssertNotNil(OpenClawSDKError.emptyResponse.errorDescription)

        // Verify the endpoint error gives actionable advice
        let endpointError = OpenClawSDKError.endpointNotEnabled.errorDescription!
        XCTAssertTrue(endpointError.contains("chatCompletions"))
    }

    func testTokenUsageDecoding() throws {
        let json = """
        {"prompt_tokens": 100, "completion_tokens": 50, "total_tokens": 150}
        """.data(using: .utf8)!

        let usage = try JSONDecoder().decode(TokenUsage.self, from: json)
        XCTAssertEqual(usage.promptTokens, 100)
        XCTAssertEqual(usage.completionTokens, 50)
        XCTAssertEqual(usage.totalTokens, 150)
    }

    func testModelInfoDecoding() throws {
        let json = """
        {"id": "openclaw:larry-agent", "object": "model", "created": 1709500000, "owned_by": "openclaw"}
        """.data(using: .utf8)!

        let model = try JSONDecoder().decode(ModelInfo.self, from: json)
        XCTAssertEqual(model.id, "openclaw:larry-agent")
        XCTAssertEqual(model.ownedBy, "openclaw")
    }

    func testChatCompletionResponseDecoding() throws {
        let json = """
        {
            "id": "chatcmpl-abc123",
            "object": "chat.completion",
            "created": 1709500000,
            "model": "openclaw:larry-agent",
            "choices": [{
                "index": 0,
                "message": {"role": "assistant", "content": "Campaign started!"},
                "finish_reason": "stop"
            }],
            "usage": {"prompt_tokens": 50, "completion_tokens": 10, "total_tokens": 60}
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: json)
        XCTAssertEqual(response.id, "chatcmpl-abc123")
        XCTAssertEqual(response.choices.count, 1)
        XCTAssertEqual(response.choices.first?.message.content, "Campaign started!")
        XCTAssertEqual(response.choices.first?.finishReason, "stop")
        XCTAssertEqual(response.usage?.totalTokens, 60)
    }
}
