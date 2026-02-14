import Testing
@testable import Lamy

@Suite("KeychainHelper", .serialized)
struct KeychainHelperTests {
    let keychain = KeychainHelper(service: "com.dstotijn.lamy.tests")
    let testKey = "test.keychain.key"

    init() {
        keychain.delete(key: testKey)
    }

    @Test func saveAndLoad() throws {
        try keychain.save(key: testKey, value: "secret123")
        let loaded = keychain.load(key: testKey)
        #expect(loaded == "secret123")
    }

    @Test func loadMissingKeyReturnsNil() {
        let loaded = keychain.load(key: "nonexistent.key")
        #expect(loaded == nil)
    }

    @Test func deleteRemovesValue() throws {
        try keychain.save(key: testKey, value: "secret")
        keychain.delete(key: testKey)
        let loaded = keychain.load(key: testKey)
        #expect(loaded == nil)
    }

    @Test func overwriteExistingValue() throws {
        try keychain.save(key: testKey, value: "first")
        try keychain.save(key: testKey, value: "second")
        let loaded = keychain.load(key: testKey)
        #expect(loaded == "second")
    }
}
