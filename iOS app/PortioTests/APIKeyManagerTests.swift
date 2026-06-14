
import Testing
@testable import Portio

struct APIKeyManagerTests {
    @Test func bundledPlistIsNotUsedForOpenRouterAPIKey() {
        #expect(APIKeyManager.getOpenRouterAPIKey() == nil)
    }

    @Test func bundledPlistIsNotUsedForSerperAPIKey() {
        #expect(APIKeyManager.getSerperAPIKey() == nil)
    }

    @Test func bundledPlistIsNotUsedForBlockRunWalletKey() {
        #expect(APIKeyManager.getBlockRunWalletKey() == nil)
    }
}
