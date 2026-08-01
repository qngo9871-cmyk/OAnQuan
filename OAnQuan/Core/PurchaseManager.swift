import StoreKit

@MainActor
class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    @Published var isPro = false
    @Published var product: Product?
    @Published var isLoadingProduct = false
    @Published var productLoadFailed = false
    @Published var isPurchasing = false
    @Published var purchaseError: String?

    private let productID = "com.quyenngo.oanquan.pro"
    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task {
            await updateEntitlementStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Product

    func loadProduct() async {
        isLoadingProduct = true
        productLoadFailed = false

        do {
            let products = try await withTimeout(seconds: 10) {
                try await Product.products(for: [self.productID])
            }
            product = products.first
            if product == nil {
                productLoadFailed = true
            }
        } catch {
            print("Failed to load product: \(error)")
            productLoadFailed = true
        }

        isLoadingProduct = false
    }

    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw CancellationError()
            }
            guard let result = try await group.next() else {
                throw CancellationError()
            }
            group.cancelAll()
            return result
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product else {
            purchaseError = "Product not available. Please try again."
            return
        }

        isPurchasing = true
        purchaseError = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                isPro = true
            case .userCancelled:
                break
            case .pending:
                purchaseError = "Purchase is pending approval."
            @unknown default:
                purchaseError = "An unexpected error occurred."
            }
        } catch {
            purchaseError = error.localizedDescription
        }

        isPurchasing = false
    }

    // MARK: - Restore

    func restorePurchases() async {
        isPurchasing = true
        purchaseError = nil

        do {
            try await AppStore.sync()
        } catch {
            purchaseError = "Could not restore purchases. Please try again."
            isPurchasing = false
            return
        }

        await updateEntitlementStatus()

        if !isPro {
            purchaseError = "No purchase found to restore."
        }

        isPurchasing = false
    }

    // MARK: - Entitlement

    func updateEntitlementStatus() async {
        #if DEBUG
        isPro = ProcessInfo.processInfo.environment["OQ_CAPTURE"] != "paywall"
        #else
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID,
               transaction.revocationDate == nil {
                isPro = true
                return
            }
        }
        isPro = false
        #endif
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.updateEntitlementStatus()
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
