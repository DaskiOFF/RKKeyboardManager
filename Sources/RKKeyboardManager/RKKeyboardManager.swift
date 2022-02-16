import UIKit

/// Менеджер работы с клавиатурой
open class KeyboardManager: NSObject {
    // MARK: - Types
    /// Событие открытия клавиатуры
    public enum Event {
        /// Будет показана
        case willShow
        /// Будет скрыта
        case willHide
        /// Изменение размера (например, изменение типа клавиатуры
        /// или отключение предиктивного ввода)
        case justChange
    }
    
    /// Тип замыкания вызываемого при изменении клавиатуры
    ///
    /// - Parameter keyboardFrame: Фрейм клавиатуры
    /// - Parameter event: Событие происходящее с клавиатурой
    public typealias OnWillChangeFrameBlock = (_ keyboardFrame: CGRect, _ event: Event) -> Void
    
    // MARK: - Properties
    private(set) public var scrollView: UIScrollView? = nil
    private var onWillChangeFrame: OnWillChangeFrameBlock?
    private var isSubscribed: Bool = false
    
    // MARK: - Init
    public override init() {
        super.init()
    }
    
    public init(with scrollView: UIScrollView?) {
        self.scrollView = scrollView
        super.init()
    }
    
    // MARK: - Setters
    public func setOnWillChangeFrameBlock(_ block: OnWillChangeFrameBlock?) {
        self.onWillChangeFrame = block
    }
    
    // MARK: - Subscribe / Unsubscribe
    /// Подписаться на обновления клавиатуры
    public func subscribe() {
        guard !isSubscribed else { return }
        isSubscribed = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    /// Отписаться от обновлений клавиатуры
    public func unsubscribe() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        isSubscribed = false
    }
    
    // MARK: - Actions
    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let beginFrame = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
              let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else {
            return
        }
        
        var event: Event = .justChange
        if beginFrame.origin.y - endFrame.origin.y > 0 && beginFrame.minY >= UIScreen.main.bounds.height {
            event = .willShow
        } else if beginFrame.origin.y - endFrame.origin.y <= 0 && endFrame.minY >= UIScreen.main.bounds.height {
            event = .willHide
        }
        
        scrollView?.contentInset.bottom = UIScreen.main.bounds.height - endFrame.minY
        
        onWillChangeFrame.flatMap({ $0(endFrame, event) })
    }
}
