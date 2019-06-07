import SwiftUI

class KeyboardAvoidingHostingController<Content>: UIHostingController<Content> where Content: View {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard isViewLoaded, let window = view.window, let userInfo = notification.userInfo else {
            return
        }

        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }

        guard let rawAnimationCurve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }

        guard let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let endFrameInWindow = window.convert(endFrame, from: nil)
        let endFrameInView = view.convert(endFrameInWindow, from: nil)
        let endFrameIntersection = view.bounds.intersection(endFrameInView)
        let keyboardHeight = view.bounds.maxY - endFrameIntersection.minY

        let options = UIView.AnimationOptions(rawValue: rawAnimationCurve << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            self.additionalSafeAreaInsets.bottom = keyboardHeight
            self.view.layoutIfNeeded()
        })
    }
}

struct KeyboardAvoidingViewController<Content>: UIViewControllerRepresentable where Content: View {
    var rootView: Content

    func makeUIViewController(context: Context) -> KeyboardAvoidingHostingController<Content> {
        return KeyboardAvoidingHostingController(rootView: rootView)
    }

    func updateUIViewController(_ uiViewController: KeyboardAvoidingHostingController<Content>, context: Context) {
        uiViewController.rootView = rootView
    }
}

public struct KeyboardAvoidingView<Content>: View where Content: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        return KeyboardAvoidingViewController(rootView: content)
    }
}

public struct KeyboardAvoiding: ViewModifier {
    public func body(content: _ViewModifier_Content<KeyboardAvoiding>) -> KeyboardAvoidingView<_ViewModifier_Content<KeyboardAvoiding>> {
        return KeyboardAvoidingView { content }
    }
}

public extension View {
    func keyboardAvoiding() -> Self.Modified<KeyboardAvoiding> {
        return modifier(KeyboardAvoiding())
    }
}
