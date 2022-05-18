// A module with library evolution enabled has two different "minimum versions".
// One, the minimum deployment target, is the lowest version that non-ABI
// declarations and bodies of non-inlinable functions will ever see. The other,
// the minimum inlining target, is the lowest version that ABI declarations and
// inlinable bodies will ever see.
//
// Test that we use the right version floor in the right places.
//
// To keep this test multi-platform, we only check fragments of diagnostics that
// don't include platform names or versions.

// REQUIRES: swift_stable_abi

// Primary execution of this test. Uses the default minimum inlining version,
// which is the version when Swift was introduced.
// RUN: %target-typecheck-verify-swift -swift-version 5 -enable-library-evolution -target %target-next-stable-abi-triple -target-min-inlining-version min


// FIXME: Re-enable with rdar://91387029
// Check that `-library-level api` implies `-target-min-inlining-version min`
// RUN/: %target-typecheck-verify-swift -swift-version 5 -enable-library-evolution -target %target-next-stable-abi-triple -library-level api


// Check that these rules are only applied when requested and that at least some
// diagnostics are not present without it.
// RUN: not %target-typecheck-verify-swift -swift-version 5 -target %target-next-stable-abi-triple 2>&1 | %FileCheck --check-prefix NON_MIN %s


// Check that -target-min-inlining-version overrides -library-level, allowing
// library owners to disable this behavior for API libraries if needed.
// RUN: not %target-typecheck-verify-swift -swift-version 5 -target %target-next-stable-abi-triple -target-min-inlining-version target -library-level api 2>&1 | %FileCheck --check-prefix NON_MIN %s


// Check that we respect -target-min-inlining-version by cranking it up high
// enough to suppress any possible errors.
// RUN: %target-swift-frontend -typecheck -disable-objc-attr-requires-foundation-module %s -swift-version 5 -enable-library-evolution -target %target-next-stable-abi-triple -target-min-inlining-version 42.0


// NON_MIN: error: expected error not produced
// NON_MIN: {'BetweenTargets' is only available in}


// MARK: - Struct definitions

/// Declaration with no availability annotation. Should be inferred as minimum
/// inlining target.
public struct NoAvailable {
  @usableFromInline internal init() {}
}

@available(macOS 10.9, iOS 7.0, tvOS 8.0, watchOS 1.0, *)
public struct BeforeInliningTarget {
  @usableFromInline internal init() {}
}

@available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *)
public struct AtInliningTarget {
  @usableFromInline internal init() {}
}

@available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *)
public struct BetweenTargets {
  @usableFromInline internal init() {}
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public struct AtDeploymentTarget {
  @usableFromInline internal init() {}
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public struct AfterDeploymentTarget {
  @usableFromInline internal init() {}
}

@available(macOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct Unavailable {
  @usableFromInline internal init() {}
}

// MARK: - Protocol definitions

public protocol NoAvailableProto {}

@available(macOS 10.9, iOS 7.0, tvOS 8.0, watchOS 1.0, *)
public protocol BeforeInliningTargetProto {}

@available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *)
public protocol AtInliningTargetProto {}

@available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *)
public protocol BetweenTargetsProto {}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public protocol AtDeploymentTargetProto {}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public protocol AfterDeploymentTargetProto {}

@available(macOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol UnavailableProto {}


// MARK: - Internal functions

//
// Both the signature and the body of internal functions should be typechecked
// using the minimum deployment target.
//

internal func internalFn( // expected-note 3 {{add @available attribute to enclosing global function}}
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets,
  _: AtDeploymentTarget,
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

// MARK: - Resilient functions

//
// The body of a resilient function is typechecked using the minimum deployment
// but the function's signature should be checked with the inlining target.
//

public func deployedUseNoAvailable( // expected-note 5 {{add @available attribute}}
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets, // expected-error {{'BetweenTargets' is only available in}}
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 10.9, iOS 7.0, tvOS 8.0, watchOS 1.0, *)
public func deployedUseBeforeInliningTarget(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets, // expected-error {{'BetweenTargets' is only available in}}
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *)
public func deployedUseAtInliningTarget(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets, // expected-error {{'BetweenTargets' is only available in}}
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *)
public func deployedUseBetweenTargets(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets,
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public func deployedUseAtDeploymentTarget(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets,
  _: AtDeploymentTarget,
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public func deployedUseAfterDeploymentTarget(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets,
  _: AtDeploymentTarget,
  _: AfterDeploymentTarget
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget()
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget()
}

@available(macOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public func alwaysUnavailable(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets,
  _: AtDeploymentTarget,
  _: AfterDeploymentTarget,
  _: Unavailable
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  _ = Unavailable()
  
  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@_spi(Private)
public func spiDeployedUseNoAvailable( // expected-note 3 {{add @available attribute}}
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets,
  _: AtDeploymentTarget,
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

// MARK: - @inlinable functions

//
// Both the bodies and signatures of inlinable functions need to be typechecked
// using the minimum inlining target.
//

@inlinable public func inlinedUseNoAvailable( // expected-note 8 {{add @available attribute}}
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets, // expected-error {{'BetweenTargets' is only available in}}
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets() // expected-error {{'BetweenTargets' is only available in}} expected-note {{add 'if #available'}}
  _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *) {
    _ = BetweenTargets()
  }
  if #available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *) {
    _ = AtDeploymentTarget()
  }
  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 10.9, iOS 7.0, tvOS 8.0, watchOS 1.0, *)
@inlinable public func inlinedUseBeforeInliningTarget(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets, // expected-error {{'BetweenTargets' is only available in}}
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets() // expected-error {{'BetweenTargets' is only available in}} expected-note {{add 'if #available'}}
  _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *) {
    _ = BetweenTargets()
  }
  if #available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *) {
    _ = AtDeploymentTarget()
  }
  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *)
@inlinable public func inlinedUseAtInliningTarget(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets, // expected-error {{'BetweenTargets' is only available in}}
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets() // expected-error {{'BetweenTargets' is only available in}} expected-note {{add 'if #available'}}
  _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *) {
    _ = BetweenTargets()
  }
  if #available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *) {
    _ = AtDeploymentTarget()
  }
  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *)
@inlinable public func inlinedUseBetweenTargets(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets,
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *) {
    _ = AtDeploymentTarget()
  }
  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
@inlinable public func inlinedUseAtDeploymentTarget(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets,
  _: AtDeploymentTarget,
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
@inlinable public func inlinedUseAfterDeploymentTarget(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets,
  _: AtDeploymentTarget,
  _: AfterDeploymentTarget
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget()
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget()
}

@available(macOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@inlinable public func inlinedAlwaysUnavailable(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets,
  _: AtDeploymentTarget,
  _: AfterDeploymentTarget,
  _: Unavailable
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  _ = Unavailable()

  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@_spi(Private)
@inlinable public func spiInlinedUseNoAvailable( // expected-note 3 {{add @available attribute}}
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets,
  _: AtDeploymentTarget,
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}


// MARK: - @_alwaysEmitIntoClient functions

// @_alwaysEmitIntoClient acts like @inlinable.

@_alwaysEmitIntoClient public func aEICUseNoAvailable( // expected-note 8 {{add @available attribute}}
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets, // expected-error {{'BetweenTargets' is only available in}}
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets() // expected-error {{'BetweenTargets' is only available in}} expected-note {{add 'if #available'}}
  _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *) {
    _ = BetweenTargets()
  }
  if #available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *) {
    _ = AtDeploymentTarget()
  }
  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}


// MARK: - @_backDeploy functions

// @_backDeploy acts like @inlinable.

@available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *)
@_backDeploy(before: macOS 999.0, iOS 999.0, tvOS 999.0, watchOS 999.0)
public func backDeployedToInliningTarget(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets, // expected-error {{'BetweenTargets' is only available in}}
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets() // expected-error {{'BetweenTargets' is only available in}} expected-note {{add 'if #available'}}
  _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *) {
    _ = BetweenTargets()
  }
  if #available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *) {
    _ = AtDeploymentTarget()
  }
  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}


// MARK: - Default arguments

// Default arguments act like @inlinable.

public func defaultArgsUseNoAvailable( // expected-note 3 {{add @available attribute}}
  _: Any = NoAvailable.self,
  _: Any = BeforeInliningTarget.self,
  _: Any = AtInliningTarget.self,
  _: Any = BetweenTargets.self, // expected-error {{'BetweenTargets' is only available in}}
  _: Any = AtDeploymentTarget.self, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: Any = AfterDeploymentTarget.self // expected-error {{'AfterDeploymentTarget' is only available in}}
) {}

@available(macOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public func defaultArgsUseUnavailable(
  _: Any = NoAvailable.self,
  _: Any = BeforeInliningTarget.self,
  _: Any = AtInliningTarget.self,
  _: Any = BetweenTargets.self,
  _: Any = AtDeploymentTarget.self,
  _: Any = AfterDeploymentTarget.self, // expected-error {{'AfterDeploymentTarget' is only available in}}
  _: Any = Unavailable.self
) {}

@_spi(Private)
public func spiDefaultArgsUseNoAvailable( // expected-note 1 {{add @available attribute}}
  _: Any = NoAvailable.self,
  _: Any = BeforeInliningTarget.self,
  _: Any = AtInliningTarget.self,
  _: Any = BetweenTargets.self,
  _: Any = AtDeploymentTarget.self,
  _: Any = AfterDeploymentTarget.self // expected-error {{'AfterDeploymentTarget' is only available in}}
) {}

@propertyWrapper
public struct PropertyWrapper<T> {
  public var wrappedValue: T

  public init(wrappedValue value: T) { self.wrappedValue = value }
  public init(_ value: T) { self.wrappedValue = value }
}

public struct PublicStruct { // expected-note 13 {{add @available attribute}}
  // Public property declarations are exposed.
  public var aPublic: NoAvailable,
             bPublic: BeforeInliningTarget,
             cPublic: AtInliningTarget,
             dPublic: BetweenTargets, // expected-error {{'BetweenTargets' is only available in}}
             ePublic: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
             fPublic: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}

  @available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *)
  public var aPublicAvailBetween: NoAvailable,
             bPublicAvailBetween: BeforeInliningTarget,
             cPublicAvailBetween: AtInliningTarget,
             dPublicAvailBetween: BetweenTargets,
             ePublicAvailBetween: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
             fPublicAvailBetween: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}

  // The inferred types of public properties are exposed.
  public var aPublicInferred = NoAvailable(),
             bPublicInferred = BeforeInliningTarget(),
             cPublicInferred = AtInliningTarget(),
             dPublicInferred = BetweenTargets(), // FIXME: Inferred type should be diagnosed
             ePublicInferred = AtDeploymentTarget(), // FIXME: Inferred type should be diagnosed
             fPublicInferred = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}}

  @available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *)
  public var aPublicInferredAvailBetween = NoAvailable(),
             bPublicInferredAvailBetween = BeforeInliningTarget(),
             cPublicInferredAvailBetween = AtInliningTarget(),
             dPublicInferredAvailBetween = BetweenTargets(),
             ePublicInferredAvailBetween = AtDeploymentTarget(), // FIXME: Inferred type should be diagnosed
             fPublicInferredAvailBetween = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}}
  
  // Property initializers are not exposed.
  public var aPublicInit: Any = NoAvailable(),
             bPublicInit: Any = BeforeInliningTarget(),
             cPublicInit: Any = AtInliningTarget(),
             dPublicInit: Any = BetweenTargets(),
             ePublicInit: Any = AtDeploymentTarget(),
             fPublicInit: Any = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}}
  
  // Internal declarations are not exposed.
  var aInternal: NoAvailable = .init(),
      bInternal: BeforeInliningTarget = .init(),
      cInternal: AtInliningTarget = .init(),
      dInternal: BetweenTargets = .init(),
      eInternal: AtDeploymentTarget = .init(),
      fInternal: AfterDeploymentTarget = .init() // expected-error {{'AfterDeploymentTarget' is only available in}}

  @available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *)
  public internal(set) var internalSetter: Void {
    @inlinable get {
      // Public inlinable getter acts like @inlinable
      _ = NoAvailable()
      _ = BeforeInliningTarget()
      _ = AtInliningTarget()
      _ = BetweenTargets()
      _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
      _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

      if #available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *) {
        _ = AtDeploymentTarget()
      }
      if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
        _ = AfterDeploymentTarget()
      }
    }
    set {
      // Private setter acts like non-inlinable
      _ = NoAvailable()
      _ = BeforeInliningTarget()
      _ = AtInliningTarget()
      _ = BetweenTargets()
      _ = AtDeploymentTarget()
      _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

      if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
        _ = AfterDeploymentTarget()
      }
    }
  }
  
  public var block: () -> () = {
    // The body of a block assigned to a public property acts like non-@inlinable
    _ = NoAvailable()
    _ = BeforeInliningTarget()
    _ = AtInliningTarget()
    _ = BetweenTargets()
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
    
    if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
      _ = AfterDeploymentTarget()
    }
  }
}

public struct PublicStructWithWrappers { // expected-note 4 {{add @available attribute}}
  // The property type is inferred from the initializer expression. The
  // expressions themselves will not be exposed.
  @PropertyWrapper public var aExplicitInit = NoAvailable()
  @PropertyWrapper public var bExplicitInit = BeforeInliningTarget()
  @PropertyWrapper public var cExplicitInit = AtInliningTarget()
  @PropertyWrapper public var dExplicitInit = BetweenTargets() // FIXME: Inferred type should be diagnosed
  @PropertyWrapper public var eExplicitInit = AtDeploymentTarget() // FIXME: Inferred type should be diagnosed
  @PropertyWrapper public var fExplicitInit = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}}
  
  // The property type is inferred from the initializer expression. The
  // expressions themselves will not be exposed.
  @PropertyWrapper(NoAvailable()) public var aExplicitInitAlt
  @PropertyWrapper(BeforeInliningTarget()) public var bExplicitInitAlt
  @PropertyWrapper(AtInliningTarget()) public var cExplicitInitAlt
  @PropertyWrapper(BetweenTargets()) public var dExplicitInitAlt  // FIXME: Inferred type should be diagnosed
  @PropertyWrapper(AtDeploymentTarget()) public var ePExplicitInitAlt  // FIXME: Inferred type should be diagnosed
  @PropertyWrapper(AfterDeploymentTarget()) public var fExplicitInitAlt // expected-error {{'AfterDeploymentTarget' is only available in}}

  // The property type is explicitly `Any` and the initializer expressions are
  // not exposed.
  @PropertyWrapper public var aAny: Any = NoAvailable()
  @PropertyWrapper public var bAny: Any = BeforeInliningTarget()
  @PropertyWrapper public var cAny: Any = AtInliningTarget()
  @PropertyWrapper public var dAny: Any = BetweenTargets()
  @PropertyWrapper public var eAny: Any = AtDeploymentTarget()
  @PropertyWrapper public var fAny: Any = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}}

  // The property type is explicitly `Any` and the initializer expressions are
  // not exposed.
  @PropertyWrapper(NoAvailable()) public var aAnyAlt: Any
  @PropertyWrapper(BeforeInliningTarget()) public var bAnyAlt: Any
  @PropertyWrapper(AtInliningTarget()) public var cAnyAlt: Any
  @PropertyWrapper(BetweenTargets()) public var dAnyAlt: Any
  @PropertyWrapper(AtDeploymentTarget()) public var eAnyAlt: Any
  @PropertyWrapper(AfterDeploymentTarget()) public var fAnyAlt: Any // expected-error {{'AfterDeploymentTarget' is only available in}}
}

@frozen public struct FrozenPublicStruct { // expected-note 9 {{add @available attribute}}
  // Public declarations are exposed.
  public var aPublic: NoAvailable,
             bPublic: BeforeInliningTarget,
             cPublic: AtInliningTarget,
             dPublic: BetweenTargets, // expected-error {{'BetweenTargets' is only available in}}
             ePublic: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
             fPublic: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}

  // Property initializers are exposed in frozen structs.
  public var aPublicInit: Any = NoAvailable(),
             bPublicInit: Any = BeforeInliningTarget(),
             cPublicInit: Any = AtInliningTarget(),
             dPublicInit: Any = BetweenTargets(), // expected-error {{'BetweenTargets' is only available in}}
             ePublicInit: Any = AtDeploymentTarget(), // expected-error {{'AtDeploymentTarget' is only available in}}
             fPublicInit: Any = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}}

  // Internal declarations are also exposed in frozen structs.
  var aInternal: NoAvailable = .init(),
      bInternal: BeforeInliningTarget = .init(),
      cInternal: AtInliningTarget = .init(),
      dInternal: BetweenTargets = .init(), // expected-error {{'BetweenTargets' is only available in}}
      eInternal: AtDeploymentTarget = .init(), // expected-error {{'AtDeploymentTarget' is only available in}}
      fInternal: AfterDeploymentTarget = .init() // expected-error {{'AfterDeploymentTarget' is only available in}}
}

@available(macOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct UnavailablePublicStruct {
  public var aPublic: NoAvailable,
             bPublic: BeforeInliningTarget,
             cPublic: AtInliningTarget,
             dPublic: BetweenTargets,
             ePublic: AtDeploymentTarget,
             fPublic: AfterDeploymentTarget, // expected-error {{'AfterDeploymentTarget' is only available in}}
             gPublic: Unavailable

  public var aPublicInit: Any = NoAvailable(),
             bPublicInit: Any = BeforeInliningTarget(),
             cPublicInit: Any = AtInliningTarget(),
             dPublicInit: Any = BetweenTargets(),
             ePublicInit: Any = AtDeploymentTarget(),
             fPublicInit: Any = AfterDeploymentTarget(), // expected-error {{'AfterDeploymentTarget' is only available in}}
             gPublicInit: Any = Unavailable()

  var aInternal: NoAvailable = .init(),
      bInternal: BeforeInliningTarget = .init(),
      cInternal: AtInliningTarget = .init(),
      dInternal: BetweenTargets = .init(),
      eInternal: AtDeploymentTarget = .init(),
      fInternal: AfterDeploymentTarget = .init(), // expected-error {{'AfterDeploymentTarget' is only available in}}
      gInternal: Unavailable = .init()
}

@_spi(Private)
public struct SPIStruct { // expected-note 3 {{add @available attribute}}
  public var aPublic: NoAvailable,
             bPublic: BeforeInliningTarget,
             cPublic: AtInliningTarget,
             dPublic: BetweenTargets,
             ePublic: AtDeploymentTarget,
             fPublic: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}

  public var aPublicInit: Any = NoAvailable(),
             bPublicInit: Any = BeforeInliningTarget(),
             cPublicInit: Any = AtInliningTarget(),
             dPublicInit: Any = BetweenTargets(),
             ePublicInit: Any = AtDeploymentTarget(),
             fPublicInit: Any = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}}

  var aInternal: NoAvailable = .init(),
      bInternal: BeforeInliningTarget = .init(),
      cInternal: AtInliningTarget = .init(),
      dInternal: BetweenTargets = .init(),
      eInternal: AtDeploymentTarget = .init(),
      fInternal: AfterDeploymentTarget = .init() // expected-error {{'AfterDeploymentTarget' is only available in}}
}

internal struct InternalStruct { // expected-note 2 {{add @available attribute}}
  // Internal declarations act like non-inlinable.
  var aInternal: NoAvailable = .init(),
      bInternal: BeforeInliningTarget = .init(),
      cInternal: AtInliningTarget = .init(),
      dInternal: BetweenTargets = .init(),
      eInternal: AtDeploymentTarget = .init(),
      fInternal: AfterDeploymentTarget = .init() // expected-error {{'AfterDeploymentTarget' is only available in}}

  @PropertyWrapper(NoAvailable()) var aWrapped: Any
  @PropertyWrapper(BeforeInliningTarget()) var bWrapped: Any
  @PropertyWrapper(AtInliningTarget()) var cWrapped: Any
  @PropertyWrapper(BetweenTargets()) var dWrapped: Any
  @PropertyWrapper(AtDeploymentTarget()) var eWrapped: Any
  @PropertyWrapper(AfterDeploymentTarget()) var fWrapped: Any // expected-error {{'AfterDeploymentTarget' is only available in}}
}


// MARK: - Extensions

//
// Extensions are externally visible if they extend a public type and (1) have
// public members or (2) declare a conformance to a public protocol. Externally
// visible extensions should be typechecked with the inlining target.
//

// OK, NoAvailable is always available, both internally and externally.
extension NoAvailable {}
extension NoAvailable {
  public func publicFunc1() {}
}

// OK, no public members and BetweenTargets is always available internally.
extension BetweenTargets {}

// OK, no public members and BetweenTargets is always available internally.
extension BetweenTargets {
  internal func internalFunc1() {}
  private func privateFunc1() {}
  fileprivate func fileprivateFunc1() {}
}

// expected-warning@+1 {{'BetweenTargets' is only available in}} expected-note@+1 {{add @available attribute to enclosing extension}}
extension BetweenTargets {
  public func publicFunc1() {}
}

// expected-warning@+1 {{'BetweenTargets' is only available in}} expected-note@+1 {{add @available attribute to enclosing extension}}
extension BetweenTargets {
  @usableFromInline
  internal func usableFromInlineFunc1() {}
}

// expected-warning@+1 {{'BetweenTargets' is only available in}} expected-note@+1 {{add @available attribute to enclosing extension}}
extension BetweenTargets {
  internal func internalFunc2() {}
  private func privateFunc2() {}
  fileprivate func fileprivateFunc2() {}
  public func publicFunc2() {}
}

// An extension with more availability than BetweenTargets.
// expected-error@+2 {{'BetweenTargets' is only available in}}
@available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *)
extension BetweenTargets {
  public func publicFunc3() {}
}

// FIXME: Can we prevent this warning when SPI members are the reason the extension is exported?
// expected-warning@+1 {{'BetweenTargets' is only available in}} expected-note@+1 {{add @available attribute to enclosing extension}}
extension BetweenTargets {
  @_spi(Private)
  public func spiFunc1() {}
}

@_spi(Private)
extension BetweenTargets {
  internal func internalFunc3() {}
  private func privateFunc3() {}
  fileprivate func fileprivateFunc3() {}
  public func spiFunc2() {}
}

@available(macOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension BetweenTargets {
  public func inheritsUnavailable(
    _: NoAvailable,
    _: BeforeInliningTarget,
    _: AtInliningTarget,
    _: BetweenTargets,
    _: AtDeploymentTarget,
    _: AfterDeploymentTarget,
    _: Unavailable
  ) { }
}

@_spi(Private)
extension BetweenTargets { // expected-note 1 {{add @available attribute to enclosing extension}}
  public func inheritsSPINoAvailable( // expected-note 1 {{add @available attribute to enclosing instance method}}
    _: NoAvailable,
    _: BeforeInliningTarget,
    _: AtInliningTarget,
    _: BetweenTargets,
    _: AtDeploymentTarget,
    _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
  ) { }
}

// Same availability as BetweenTargets but internal instead of public.
@available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *)
internal struct BetweenTargetsInternal {}

// OK, extensions on internal types are never visible externally.
extension BetweenTargetsInternal {}
extension BetweenTargetsInternal {
  public func publicFunc() {}
}

// expected-error@+1 {{'AfterDeploymentTarget' is only available in}} expected-note@+1 {{add @available attribute to enclosing extension}}
extension AfterDeploymentTarget {}

// expected-error@+1 {{'AfterDeploymentTarget' is only available in}} expected-note@+1 {{add @available attribute to enclosing extension}}
extension AfterDeploymentTarget {
  internal func internalFunc1() {}
  private func privateFunc1() {}
  fileprivate func fileprivateFunc1() {}
}

// expected-error@+1 {{'AfterDeploymentTarget' is only available in}} expected-note@+1 {{add @available attribute to enclosing extension}}
extension AfterDeploymentTarget {
  public func publicFunc1() {}
}


// MARK: Protocol conformances

internal protocol InternalProto {}

extension NoAvailable: InternalProto {}
extension BeforeInliningTarget: InternalProto {}
extension AtInliningTarget: InternalProto {}
extension BetweenTargets: InternalProto {}
extension AtDeploymentTarget: InternalProto {}
extension AfterDeploymentTarget: InternalProto {} // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add @available attribute to enclosing extension}}

public protocol PublicProto {}

extension NoAvailable: PublicProto {}
extension BeforeInliningTarget: PublicProto {}
extension AtInliningTarget: PublicProto {}
extension BetweenTargets: PublicProto {} // expected-warning {{'BetweenTargets' is only available in}} expected-note {{add @available attribute to enclosing extension}}
extension AtDeploymentTarget: PublicProto {} // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add @available attribute to enclosing extension}}
extension AfterDeploymentTarget: PublicProto {} // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add @available attribute to enclosing extension}}


// MARK: - Associated types

public protocol NoAvailableProtoWithAssoc { // expected-note 3 {{add @available attribute to enclosing protocol}}
  associatedtype A: NoAvailableProto
  associatedtype B: BeforeInliningTargetProto
  associatedtype C: AtInliningTargetProto
  associatedtype D: BetweenTargetsProto // expected-error {{'BetweenTargetsProto' is only available in}}
  associatedtype E: AtDeploymentTargetProto // expected-error {{'AtDeploymentTargetProto' is only available in}}
  associatedtype F: AfterDeploymentTargetProto // expected-error {{'AfterDeploymentTargetProto' is only available in}}
}

@available(macOS 10.9, iOS 7.0, tvOS 8.0, watchOS 1.0, *)
public protocol BeforeInliningTargetProtoWithAssoc {
  associatedtype A: NoAvailableProto
  associatedtype B: BeforeInliningTargetProto
  associatedtype C: AtInliningTargetProto
  associatedtype D: BetweenTargetsProto // expected-error {{'BetweenTargetsProto' is only available in}}
  associatedtype E: AtDeploymentTargetProto // expected-error {{'AtDeploymentTargetProto' is only available in}}
  associatedtype F: AfterDeploymentTargetProto // expected-error {{'AfterDeploymentTargetProto' is only available in}}
}

@available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *)
public protocol AtInliningTargetProtoWithAssoc {
  associatedtype A: NoAvailableProto
  associatedtype B: BeforeInliningTargetProto
  associatedtype C: AtInliningTargetProto
  associatedtype D: BetweenTargetsProto // expected-error {{'BetweenTargetsProto' is only available in}}
  associatedtype E: AtDeploymentTargetProto // expected-error {{'AtDeploymentTargetProto' is only available in}}
  associatedtype F: AfterDeploymentTargetProto // expected-error {{'AfterDeploymentTargetProto' is only available in}}
}

@available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *)
public protocol BetweenTargetsProtoWithAssoc {
  associatedtype A: NoAvailableProto
  associatedtype B: BeforeInliningTargetProto
  associatedtype C: AtInliningTargetProto
  associatedtype D: BetweenTargetsProto
  associatedtype E: AtDeploymentTargetProto // expected-error {{'AtDeploymentTargetProto' is only available in}}
  associatedtype F: AfterDeploymentTargetProto // expected-error {{'AfterDeploymentTargetProto' is only available in}}
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public protocol AtDeploymentTargetProtoWithAssoc {
  associatedtype A: NoAvailableProto
  associatedtype B: BeforeInliningTargetProto
  associatedtype C: AtInliningTargetProto
  associatedtype D: BetweenTargetsProto
  associatedtype E: AtDeploymentTargetProto
  associatedtype F: AfterDeploymentTargetProto // expected-error {{'AfterDeploymentTargetProto' is only available in}}
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public protocol AfterDeploymentTargetProtoWithAssoc {
  associatedtype A: NoAvailableProto
  associatedtype B: BeforeInliningTargetProto
  associatedtype C: AtInliningTargetProto
  associatedtype D: BetweenTargetsProto
  associatedtype E: AtDeploymentTargetProto
  associatedtype F: AfterDeploymentTargetProto
}

@available(macOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol UnavailableProtoWithAssoc {
  associatedtype A: NoAvailableProto
  associatedtype B: BeforeInliningTargetProto
  associatedtype C: AtInliningTargetProto
  associatedtype D: BetweenTargetsProto
  associatedtype E: AtDeploymentTargetProto
  associatedtype F: AfterDeploymentTargetProto // expected-error {{'AfterDeploymentTargetProto' is only available in}}
  associatedtype G: UnavailableProto
}

@_spi(Private)
public protocol SPINoAvailableProtoWithAssoc { // expected-note 1 {{add @available attribute to enclosing protocol}}
  associatedtype A: NoAvailableProto
  associatedtype B: BeforeInliningTargetProto
  associatedtype C: AtInliningTargetProto
  associatedtype D: BetweenTargetsProto
  associatedtype E: AtDeploymentTargetProto
  associatedtype F: AfterDeploymentTargetProto // expected-error {{'AfterDeploymentTargetProto' is only available in}}
}

// MARK: - Type aliases

public enum PublicNoAvailableEnumWithTypeAliases { // expected-note 3 {{add @available attribute to enclosing enum}}
  public typealias A = NoAvailable
  public typealias B = BeforeInliningTarget
  public typealias C = AtInliningTarget
  public typealias D = BetweenTargets // expected-error {{'BetweenTargets' is only available in}} expected-note {{add @available attribute to enclosing type alias}}
  public typealias E = AtDeploymentTarget // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add @available attribute to enclosing type alias}}
  public typealias F = AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add @available attribute to enclosing type alias}}
}

@available(macOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public enum UnavailableEnumWithTypeAliases {
  public typealias A = NoAvailable
  public typealias B = BeforeInliningTarget
  public typealias C = AtInliningTarget
  public typealias D = BetweenTargets
  public typealias E = AtDeploymentTarget
  public typealias F = AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add @available attribute to enclosing type alias}}
  public typealias G = Unavailable
}

@_spi(Private)
public enum SPIEnumWithTypeAliases { // expected-note 1 {{add @available attribute to enclosing enum}}
  public typealias A = NoAvailable
  public typealias B = BeforeInliningTarget
  public typealias C = AtInliningTarget
  public typealias D = BetweenTargets
  public typealias E = AtDeploymentTarget
  public typealias F = AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add @available attribute to enclosing type alias}}
}

enum InternalNoAvailableEnumWithTypeAliases { // expected-note {{add @available attribute to enclosing enum}}
  public typealias A = NoAvailable
  public typealias B = BeforeInliningTarget
  public typealias C = AtInliningTarget
  public typealias D = BetweenTargets
  public typealias E = AtDeploymentTarget
  public typealias F = AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add @available attribute to enclosing type alias}}
}


// MARK: - Top-level code

// Top-level code, if somehow present in a resilient module, is treated like
// a non-inlinable function.
defer {
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
}
_ = NoAvailable()
_ = BeforeInliningTarget()
_ = AtInliningTarget()
_ = BetweenTargets()
_ = AtDeploymentTarget()
_ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
  _ = AfterDeploymentTarget()
}

