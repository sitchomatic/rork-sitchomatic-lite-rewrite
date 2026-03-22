import Foundation
import WebKit

final class SimpleHardcodedLoginService {
    static let shared = SimpleHardcodedLoginService()

    func buildLoginJS(
        email: String,
        password: String,
        selectors: LoginSiteSelectors,
        speedMode: SpeedMode,
        postPageSettleDelayMs: Int
    ) -> String {
        let typingDelay = speedMode.typingDelayMs
        let actionDelay = speedMode.actionDelayMs
        let postSubmitWait = speedMode.postSubmitWaitMs

        let escapedEmail = email
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        let escapedPassword = password
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")

        return """
        (async function() {
            function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

            function clickField(el) {
                el.focus();
                el.click();
                el.dispatchEvent(new MouseEvent('mousedown', {bubbles: true}));
                el.dispatchEvent(new MouseEvent('mouseup', {bubbles: true}));
                el.dispatchEvent(new MouseEvent('click', {bubbles: true}));
                if (el.select) el.select();
            }

            async function typeText(el, text, delay) {
                el.value = '';
                el.dispatchEvent(new Event('input', {bubbles: true}));
                for (const ch of text) {
                    el.value += ch;
                    el.dispatchEvent(new Event('input', {bubbles: true}));
                    el.dispatchEvent(new KeyboardEvent('keydown', {key: ch, bubbles: true}));
                    el.dispatchEvent(new KeyboardEvent('keypress', {key: ch, bubbles: true}));
                    el.dispatchEvent(new KeyboardEvent('keyup', {key: ch, bubbles: true}));
                    await sleep(delay);
                }
                el.dispatchEvent(new Event('change', {bubbles: true}));
                el.dispatchEvent(new Event('blur', {bubbles: true}));
            }

            function checkDisabled() {
                const body = document.body ? document.body.innerText.toLowerCase() : '';
                const permKeywords = ['has been disabled', 'permanently disabled', 'account is disabled', 'blacklisted', 'account closed', 'account terminated'];
                const tempKeywords = ['temporarily disabled', 'temporary disable', 'temporarily locked', 'too many attempts', 'try again later', 'suspended', 'blocked', 'temporarily unavailable'];
                for (const kw of permKeywords) {
                    if (body.includes(kw)) return {type: 'perm', keyword: kw};
                }
                for (const kw of tempKeywords) {
                    if (body.includes(kw)) return {type: 'temp', keyword: kw};
                }
                return null;
            }

            function checkSuccess() {
                const body = document.body ? document.body.innerText.toLowerCase() : '';
                return body.includes('balance') || body.includes('wallet') || body.includes('my account') || body.includes('cashier') || body.includes('deposit');
            }

            function getButtonSignature(el) {
                if (!el) return '';
                try {
                    const style = window.getComputedStyle(el);
                    return style.backgroundColor + '|' + style.color + '|' + style.opacity + '|' + el.disabled + '|' + el.className;
                } catch(e) { return ''; }
            }

            try {
                await sleep(\(postPageSettleDelayMs));

                const emailEl = document.querySelector('\(selectors.emailSelector)');
                if (!emailEl) return JSON.stringify({status: 'failed', error: 'Email field not found: \(selectors.emailSelector)'});
                clickField(emailEl);
                await sleep(\(actionDelay));
                await typeText(emailEl, '\(escapedEmail)', \(typingDelay));
                await sleep(\(actionDelay));

                const passEl = document.querySelector('\(selectors.passwordSelector)');
                if (!passEl) return JSON.stringify({status: 'failed', error: 'Password field not found: \(selectors.passwordSelector)'});
                clickField(passEl);
                await sleep(\(actionDelay));
                await typeText(passEl, '\(escapedPassword)', \(typingDelay));
                await sleep(\(actionDelay));

                const submitEl = document.querySelector('\(selectors.submitSelector)');
                if (!submitEl) return JSON.stringify({status: 'failed', error: 'Submit button not found: \(selectors.submitSelector)'});

                const originalSig = getButtonSignature(submitEl);

                for (let attempt = 0; attempt < 4; attempt++) {
                    submitEl.click();
                    submitEl.dispatchEvent(new MouseEvent('click', {bubbles: true, cancelable: true}));
                    if (submitEl.form && submitEl.type === 'submit') {
                        try { submitEl.form.dispatchEvent(new Event('submit', {bubbles: true})); } catch(e) {}
                    }

                    await sleep(\(postSubmitWait));

                    const disabledCheck = checkDisabled();
                    if (disabledCheck) {
                        if (disabledCheck.type === 'perm') {
                            return JSON.stringify({status: 'permDisabled', detail: disabledCheck.keyword});
                        }
                        return JSON.stringify({status: 'tempDisabled', detail: disabledCheck.keyword});
                    }

                    if (checkSuccess()) {
                        return JSON.stringify({status: 'success', detail: 'Login confirmed on attempt ' + (attempt + 1)});
                    }

                    if (attempt < 3) {
                        let waited = 0;
                        const maxWait = 6000;
                        while (waited < maxWait) {
                            await sleep(150);
                            waited += 150;
                            const currentSig = getButtonSignature(submitEl);
                            if (currentSig === originalSig && !submitEl.disabled) break;
                        }
                        await sleep(1000);

                        const midCheck = checkDisabled();
                        if (midCheck) {
                            if (midCheck.type === 'perm') {
                                return JSON.stringify({status: 'permDisabled', detail: midCheck.keyword});
                            }
                            return JSON.stringify({status: 'tempDisabled', detail: midCheck.keyword});
                        }
                        if (checkSuccess()) {
                            return JSON.stringify({status: 'success', detail: 'Login confirmed between attempts ' + (attempt + 1) + '-' + (attempt + 2)});
                        }
                    }
                }

                const finalDisabled = checkDisabled();
                if (finalDisabled) {
                    if (finalDisabled.type === 'perm') {
                        return JSON.stringify({status: 'permDisabled', detail: finalDisabled.keyword});
                    }
                    return JSON.stringify({status: 'tempDisabled', detail: finalDisabled.keyword});
                }

                if (checkSuccess()) {
                    return JSON.stringify({status: 'success', detail: 'Login confirmed after all attempts'});
                }

                return JSON.stringify({status: 'unsure', detail: 'No clear result after 4 submit attempts'});
            } catch(e) {
                return JSON.stringify({status: 'failed', error: e.message});
            }
        })();
        """
    }

    nonisolated struct LoginResult: Sendable {
        let status: LoginAttemptStatus
        let detail: String?
        let error: String?
    }

    func parseResult(_ jsonString: String?) -> LoginResult {
        guard let jsonString, !jsonString.isEmpty,
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let status = json["status"] as? String else {
            return LoginResult(status: .failed, detail: nil, error: "No response from page")
        }

        let detail = json["detail"] as? String
        let error = json["error"] as? String

        switch status {
        case "success": return LoginResult(status: .success, detail: detail, error: nil)
        case "tempDisabled": return LoginResult(status: .tempDisabled, detail: detail, error: nil)
        case "permDisabled": return LoginResult(status: .permDisabled, detail: detail, error: nil)
        case "unsure": return LoginResult(status: .unsure, detail: detail, error: nil)
        case "failed": return LoginResult(status: .failed, detail: detail, error: error)
        default: return LoginResult(status: .failed, detail: detail, error: error)
        }
    }
}
