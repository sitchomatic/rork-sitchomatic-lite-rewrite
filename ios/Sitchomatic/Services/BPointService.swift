import Foundation

final class BPointService {
    static let shared = BPointService()
    static let paymentURL = "https://www.bpoint.com.au/payments/billpayment/Payment/Index"

    private let names = ["John Smith", "Jane Doe", "Michael Brown", "Sarah Wilson", "David Lee",
                         "Emma Johnson", "James Taylor", "Olivia Martin", "William Davis", "Sophia Garcia"]

    func randomBiller(from billers: [BPointBiller]) -> BPointBiller? {
        billers.filter(\.isActive).randomElement()
    }

    func randomReferenceValue() -> String {
        if Bool.random() {
            return names.randomElement() ?? "John Smith"
        } else {
            return String((0..<11).map { _ in Character(String(Int.random(in: 0...9))) })
        }
    }

    func buildBillerLookupJS(billerCode: String) -> String {
        """
        (function() {
            const input = document.querySelector('input[name="BillerCode"], input[id*="biller"], input[id*="Biller"]');
            if (!input) return JSON.stringify({status: 'failed', error: 'Biller code input not found'});
            input.value = '\(billerCode)';
            input.dispatchEvent(new Event('input', {bubbles: true}));
            input.dispatchEvent(new Event('change', {bubbles: true}));
            const btn = document.querySelector('button[type="submit"], input[type="submit"], button.btn-primary');
            if (btn) btn.click();
            return JSON.stringify({status: 'ok'});
        })();
        """
    }

    func buildFillFormJS(amount: String, cardType: CardType) -> String {
        let cardSelectors = cardType.selectorPatterns.map { "'\($0)'" }.joined(separator: ",")
        let namePool = names.map { "'\($0)'" }.joined(separator: ",")
        return """
        (async function() {
            function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

            function randomRef() {
                const names = [\(namePool)];
                if (Math.random() > 0.5) {
                    return names[Math.floor(Math.random() * names.length)];
                } else {
                    let num = '';
                    for (let i = 0; i < 11; i++) num += Math.floor(Math.random() * 10);
                    return num;
                }
            }

            try {
                await sleep(1500);

                const inputs = Array.from(document.querySelectorAll('input[type="text"], input[type="number"]'))
                    .filter(i => {
                        const r = i.getBoundingClientRect();
                        return r.width > 0 && r.height > 0 && !i.disabled && !i.readOnly;
                    });

                const cardInputs = Array.from(document.querySelectorAll('input[name*="card"], input[id*="card"], input[name*="Card"]'));
                const amountInputs = Array.from(document.querySelectorAll('input[name*="mount"], input[id*="mount"], input[name*="Amount"]'));

                const refInputs = inputs.filter(i => !cardInputs.includes(i) && !amountInputs.includes(i));

                for (const inp of refInputs) {
                    const val = randomRef();
                    inp.value = val;
                    inp.dispatchEvent(new Event('input', {bubbles: true}));
                    inp.dispatchEvent(new Event('change', {bubbles: true}));
                    await sleep(200);
                }

                for (const inp of amountInputs) {
                    inp.value = '\(amount)';
                    inp.dispatchEvent(new Event('input', {bubbles: true}));
                    inp.dispatchEvent(new Event('change', {bubbles: true}));
                }

                const selectors = [\(cardSelectors)];
                for (const sel of selectors) {
                    const el = document.querySelector(sel);
                    if (el) { el.click(); break; }
                }

                await sleep(500);
                const submitBtn = document.querySelector('button[type="submit"], input[type="submit"]');
                if (submitBtn) submitBtn.click();

                await sleep(3000);
                const body = document.body ? document.body.innerText.toLowerCase() : '';
                if (body.includes('approved') || body.includes('success') || body.includes('receipt')) {
                    return JSON.stringify({status: 'success'});
                }
                if (body.includes('declined') || body.includes('error') || body.includes('failed')) {
                    return JSON.stringify({status: 'failed', error: 'Payment declined'});
                }
                return JSON.stringify({status: 'unsure'});
            } catch(e) {
                return JSON.stringify({status: 'failed', error: e.message});
            }
        })();
        """
    }
}
