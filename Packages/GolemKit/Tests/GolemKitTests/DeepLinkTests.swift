import Foundation
import Testing
@testable import GolemKit

struct DeepLinkTests {
    @Test func pleaLinkRoundTrips() {
        let id = UUID()
        #expect(DeepLink.pleaGroupID(from: DeepLink.plea(groupID: id)) == id)
    }

    @Test func otherLinksAreIgnored() {
        #expect(DeepLink.pleaGroupID(from: URL(string: "golem://home")!) == nil)
        #expect(DeepLink.pleaGroupID(from: URL(string: "https://plea/\(UUID())")!) == nil)
    }
}
