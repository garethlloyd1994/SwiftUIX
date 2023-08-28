//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(macOS) || os(tvOS) || targetEnvironment(macCatalyst)

import SwiftUI

public protocol _AppKitOrUIKitRepresented: AnyObject, AppKitOrUIKitResponder {
    var representatableStateFlags: _AppKitOrUIKitRepresentableStateFlags { get set }
    var representableCache: _AppKitOrUIKitRepresentableCache { get set }
    
    func _performOrSchedulePublishingChanges(_: @escaping () -> Void)
}

public struct _AppKitOrUIKitRepresentableStateFlags: OptionSet {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let updateInProgress = Self(rawValue: 1 << 0)
    public static let didUpdateAtLeastOnce = Self(rawValue: 1 << 1)
    public static let dismantled = Self(rawValue: 1 << 2)
}

public struct _AppKitOrUIKitRepresentableCache: ExpressibleByNilLiteral {
    public enum Attribute {
        case intrinsicContentSize
    }
    
    var _cachedIntrinsicContentSize: CGSize? = nil
    var _sizeThatFitsCache: [AppKitOrUIKitLayoutSizeProposal: CGSize] = [:]
    
    public init(nilLiteral: ()) {
        
    }
    
    mutating func invalidate(_ attribute: Attribute) {
        switch attribute {
            case .intrinsicContentSize:
                _cachedIntrinsicContentSize = nil
                _sizeThatFitsCache = [:]
        }
    }
}

extension AppKitOrUIKitResponder {
    @objc open func _performOrSchedulePublishingChanges(
        @_implicitSelfCapture _ operation: @escaping () -> Void
    ) {
        if let responder = self as? _AppKitOrUIKitRepresented {
            if responder.representatableStateFlags.contains(.updateInProgress) {
                DispatchQueue.main.async {
                    operation()
                }
            } else {
                operation()
            }
        } else {
            operation()
        }
    }
}

extension _AppKitOrUIKitRepresented {
    public func _performOrSchedulePublishingChanges(
        @_implicitSelfCapture _ operation: @escaping () -> Void
    ) {
        if representatableStateFlags.contains(.updateInProgress) {
            DispatchQueue.main.async {
                operation()
            }
        } else {
            operation()
        }
    }
}

#endif