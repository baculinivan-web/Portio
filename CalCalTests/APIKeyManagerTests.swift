
import Testing
@testable import CalCal

struct APIKeyManagerTests {
    @Test func testGetOpenRouterAPIKey() {
        let key = APIKeyManager.getOpenRouterAPIKey()
        // We don't assert the value as it depends on the environment/file
        // We just verify the API exists and doesn't crash
    }
}
