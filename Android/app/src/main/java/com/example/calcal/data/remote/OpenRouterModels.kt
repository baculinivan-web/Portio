package com.example.calcal.data.remote

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

@Serializable
data class OpenRouterRequest(
    val model: String,
    val messages: List<Message>,
    val tools: List<Tool>? = null,
    @SerialName("tool_choice") val toolChoice: String? = null,
    @SerialName("response_format") val responseFormat: ResponseFormat? = null,
    val reasoning: Reasoning? = null
) {
    @Serializable
    data class Message(
        val role: String,
        val content: String? = null,
        @SerialName("tool_calls") val toolCalls: List<ToolCall>? = null,
        @SerialName("tool_call_id") val toolCallId: String? = null
    )

    @Serializable
    data class Tool(
        val type: String = "function",
        val function: FunctionDef
    )

    @Serializable
    data class FunctionDef(
        val name: String,
        val description: String,
        val parameters: JsonElement
    )

    @Serializable
    data class ToolCall(
        val id: String,
        val type: String = "function",
        val function: FunctionCall
    )

    @Serializable
    data class FunctionCall(
        val name: String,
        val arguments: String
    )

    @Serializable
    data class ResponseFormat(val type: String = "json_object")

    @Serializable
    data class Reasoning(val effort: String = "low")
}

@Serializable
data class OpenRouterResponse(
    val choices: List<Choice>
) {
    @Serializable
    data class Choice(
        val message: Message,
        @SerialName("finish_reason") val finishReason: String? = null
    )

    @Serializable
    data class Message(
        val role: String = "assistant",
        val content: String? = null,
        @SerialName("tool_calls") val toolCalls: List<OpenRouterRequest.ToolCall>? = null
    )
}

@Serializable
data class OpenRouterErrorResponse(
    val error: ErrorDetail
) {
    @Serializable
    data class ErrorDetail(val message: String)
}
