import KairosKit

/// Retroactive protocol conformance — KairosSharedState already implements all
/// required properties; this declaration wires it into the DI seam.
extension KairosSharedState: @retroactive KairosSharedStateProtocol {}
