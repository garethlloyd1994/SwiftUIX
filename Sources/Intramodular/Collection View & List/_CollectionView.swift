//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift
import SwiftUI

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)

struct _CollectionView<
    SectionType,
    SectionIdentifierType: Hashable,
    ItemType,
    ItemIdentifierType: Hashable,
    SectionHeader: View,
    SectionFooter: View,
    RowContent: View
>: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIHostingCollectionViewController<
        SectionType,
        SectionIdentifierType,
        ItemType,
        ItemIdentifierType,
        SectionHeader,
        SectionFooter,
        RowContent
    >
    
    typealias Configuration = _CollectionViewConfiguration
    
    private let dataSource: UIViewControllerType.DataSource
    private let viewProvider: ViewProvider
    
    @Environment(\._collectionViewConfiguration) var configuration: Configuration
    
    public func makeUIViewController(context: Context) -> UIViewControllerType {
        .init(
            configuration: configuration,
            viewProvider: viewProvider,
            dataSource: dataSource
        )
    }
    
    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        populateCollectionViewProxy: do {
            if let _collectionViewProxy = context.environment._collectionViewProxy {
                if _collectionViewProxy.wrappedValue.base !== uiViewController {
                    DispatchQueue.main.async {
                        _collectionViewProxy.wrappedValue.base = uiViewController
                    }
                }
            }
        }
        
        updateCollectionViewLayout: do {
            let collectionViewLayout = _CollectionViewLayout(
                collectionViewController: uiViewController,
                base: context.environment.collectionViewLayout
            )
            
            if uiViewController.collectionViewLayout.hashValue != collectionViewLayout.hashValue {
                uiViewController.collectionViewLayout = collectionViewLayout
            }
        }
        
        uiViewController._animateDataSourceDifferences = context.transaction.isAnimated
        uiViewController._dynamicViewContentTraitValues = context.environment._dynamicViewContentTraitValues
        uiViewController._scrollViewConfiguration = context.environment._scrollViewConfiguration
        uiViewController.configuration = context.environment._collectionViewConfiguration
        uiViewController.viewProvider = viewProvider
        
        uiViewController.dataSource = dataSource
        
        uiViewController.refreshVisibleCellsAndSupplementaryViews()
    }
}

// MARK: - Initializers -

extension _CollectionView {
    @_disfavoredOverload
    init<Data: RandomAccessCollection>(
        _ data: Data,
        sectionHeader: @escaping (SectionType) -> SectionHeader,
        sectionFooter: @escaping (SectionType) -> SectionFooter,
        rowContent: @escaping (SectionType, ItemType) -> RowContent
    ) where
        SectionType: Identifiable,
        SectionIdentifierType == _IdentifierHashedValue<SectionType>,
        ItemType: Identifiable,
        ItemIdentifierType == _IdentifierHashedValue<ItemType>,
        Data.Element == ListSection<SectionType, ItemType>
    {
        self.dataSource = .init(
            payload: .static(.init(data)),
            identifierMap: .init(
                getSectionID: { .init($0) },
                getSectionFromID: { $0.value },
                getItemID: { .init($0) },
                getItemFromID: { $0.value }
            )
        )
        
        self.viewProvider = .init(
            sectionHeader: sectionHeader,
            sectionFooter: sectionFooter,
            rowContent: rowContent
        )
    }
    
    init(
        _ data: UIViewControllerType.DataSource.Payload,
        sectionHeader: @escaping (SectionType) -> SectionHeader,
        sectionFooter: @escaping (SectionType) -> SectionFooter,
        rowContent: @escaping (SectionType, ItemType) -> RowContent
    ) where
        SectionType: Hashable,
        ItemType: Hashable,
        SectionIdentifierType == SectionType,
        ItemIdentifierType == ItemType
    {
        self.dataSource = .init(
            payload: data,
            identifierMap: .init(
                getSectionID: { $0 },
                getSectionFromID: { $0 },
                getItemID: { $0 },
                getItemFromID: { $0 }
            )
        )
        
        self.viewProvider = .init(
            sectionHeader: sectionHeader,
            sectionFooter: sectionFooter,
            rowContent: rowContent
        )
    }
    
    init<Data: RandomAccessCollection>(
        _ data: Data,
        sectionHeader: @escaping (SectionType) -> SectionHeader,
        sectionFooter: @escaping (SectionType) -> SectionFooter,
        rowContent: @escaping (SectionType, ItemType) -> RowContent
    ) where
        SectionType: Hashable,
        ItemType: Hashable,
        SectionIdentifierType == SectionType,
        ItemIdentifierType == ItemType,
        Data.Element == ListSection<SectionType, ItemType>
    {
        self.init(
            .static(.init(data)),
            sectionHeader: sectionHeader,
            sectionFooter: sectionFooter,
            rowContent: { rowContent($0, $1) }
        )
    }
}

// MARK: - Auxiliary Implementation -

extension _CollectionView {
    public struct _CollectionViewLayout: CollectionViewLayout, Hashable {
        weak var collectionViewController: NSObject?
        
        let base: CollectionViewLayout
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(collectionViewController?.hashValue)
            hasher.combine(base.hashValue)
        }
        
        public func _toUICollectionViewLayout() -> UICollectionViewLayout {
            base._toUICollectionViewLayout()
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
    }
    
    struct ViewProvider {
        let sectionHeader: (SectionType) -> SectionHeader
        let sectionFooter: (SectionType) -> SectionFooter
        
        let rowContent: (SectionType, ItemType) -> RowContent
        
        func sectionContent(for kind: String) -> ((SectionType) -> AnyView)? {
            switch kind {
                case UICollectionView.elementKindSectionHeader: do {
                    if SectionHeader.self != EmptyView.self && SectionHeader.self != Never.self {
                        return { sectionHeader($0).eraseToAnyView() }
                    } else {
                        return nil
                    }
                }
                case UICollectionView.elementKindSectionFooter:
                    if SectionFooter.self != EmptyView.self && SectionFooter.self != Never.self {
                        return { sectionFooter($0).eraseToAnyView() }
                    } else {
                        return nil
                    }
                default: do {
                    assertionFailure()
                    
                    return nil
                }
            }
        }
    }
}

#endif
