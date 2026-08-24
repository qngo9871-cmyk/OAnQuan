import SwiftUI

struct UpgradeView: View {
    @StateObject private var purchases = PurchaseManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundStyle(.brown)

            Text(L("upgrade.title"))
                .font(.title2.bold())

            Text(L(purchases.isPro || purchases.trialActive ? "upgrade.subtitle" : "upgrade.subtitle.trialended"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            VStack(alignment: .leading, spacing: 10) {
                featureRow("brain.head.profile", L("upgrade.feature.hardAI"))
                featureRow("person.2.fill", L("upgrade.feature.playFriend"))
                featureRow("infinity", L("upgrade.feature.noAds"))
            }
            .padding(.horizontal, 30)

            if purchases.isPro {
                Text(L("upgrade.owned")).font(.headline).foregroundStyle(.green)
            } else if purchases.isLoadingProduct {
                ProgressView()
            } else if let product = purchases.product {
                Button {
                    Task { await purchases.purchase() }
                } label: {
                    Text(purchases.isPurchasing ? "…" : String(format: L("upgrade.buy"), product.displayPrice))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(purchases.isPurchasing)
                .padding(.horizontal, 30)
            } else if purchases.productLoadFailed {
                #if DEBUG
                if ProcessInfo.processInfo.environment["OQ_CAPTURE"] == "upgrade" {
                    // App Store screenshot capture only: local StoreKit testing
                    // consistently fails to load a real Product via a bare
                    // `simctl launch` (no Xcode test host attached) — same
                    // known limitation as Janggi/Dara/Makruk. Renders the real,
                    // shipping button copy/price so the screenshot reflects the
                    // actual purchase UI instead of the simulator-only error
                    // fallback below. Never shown to a real user — gated on
                    // both #if DEBUG and the OQ_CAPTURE screenshot launch arg.
                    Button {} label: {
                        Text(String(format: L("upgrade.buy"), "$2.99"))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 30)
                } else {
                    productLoadFailedView
                }
                #else
                productLoadFailedView
                #endif
            } else {
                Text(L("upgrade.unavailable")).foregroundStyle(.secondary)
            }

            if let error = purchases.purchaseError {
                Text(error).font(.caption).foregroundStyle(.red).multilineTextAlignment(.center)
            }

            if !purchases.isPro {
                Button {
                    Task { await purchases.restorePurchases() }
                } label: {
                    Text(L("upgrade.restore")).font(.caption).foregroundStyle(.secondary)
                }
                .disabled(purchases.isPurchasing)
            }

            Button(L("upgrade.close")) { dismiss() }
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.top, 40)
        .task { await purchases.loadProduct() }
        .onChange(of: purchases.isPro) { isPro in
            if isPro { dismiss() }
        }
    }

    private var productLoadFailedView: some View {
        VStack(spacing: 8) {
            Text(L("upgrade.loadFailed"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button(L("upgrade.tryAgain")) { Task { await purchases.loadProduct() } }
                .buttonStyle(.bordered)
        }
    }

    private func featureRow(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(.brown).frame(width: 22)
            Text(text)
            Spacer()
        }
        .font(.subheadline)
    }
}

#Preview { UpgradeView() }
