import Foundation
import Testing
@testable import GolemKit

struct DeepLinkTests {
    @Test func talkLinkRoundTrips() {
        let id = UUID()
        #expect(DeepLink.talkGroupID(from: DeepLink.talk(groupID: id)) == id)
    }

    @Test func otherLinksAreIgnored() {
        #expect(DeepLink.talkGroupID(from: URL(string: "golem://home")!) == nil)
        #expect(DeepLink.talkGroupID(from: URL(string: "https://talk/\(UUID())")!) == nil)
    }
}
