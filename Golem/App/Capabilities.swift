/// What this build of Golem can do.
///
/// There are two flavours (see project.yml):
/// - **Golem**: Screen Time shields + Shortcuts timer. Needs a paid Apple
///   Developer account and a real iPhone.
/// - **GolemLite**: Shortcuts timer and Dynamic Island only. Runs with a free
///   account and in the Simulator.
enum Capabilities {
    /// Screen Time (app picker, monitoring, shields) is usable.
    /// Never in the Simulator, which has no Screen Time.
    #if SCREEN_TIME && !targetEnvironment(simulator)
    static let screenTime = true
    #else
    static let screenTime = false
    #endif
}
