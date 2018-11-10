//
//  TVAlert.swift
//  TVAlert
//
//  Copyright (c) 2016 adrum. All rights reserved.
//

import UIKit

private protocol TVAlertActionDelegate {
    func didChangeEnabled(_ action:TVAlertAction, enabled:Bool)
}

open class TVAlertAction: NSObject {
    open fileprivate(set) var title:String?
    open fileprivate(set) var handler:((TVAlertAction)->Void)?
    open fileprivate(set) var style: UIAlertActionStyle = .default
    open var isEnabled:Bool = true {
        didSet {
            self.delegate?.didChangeEnabled(self, enabled: self.isEnabled)
        }
    }
    fileprivate var delegate:TVAlertActionDelegate?
    
    public convenience init(title: String?, style: UIAlertActionStyle, handler: ((TVAlertAction) -> Void)?) {
        self.init()
        self.title = title
        self.handler = handler
        self.style = style
    }
}

open class TVAlertController : UIViewController {
    
    // Private vars
    fileprivate var backgroundImage:UIImage?
    fileprivate var contentView:UIView?
    fileprivate var firstButtonTouched:UIButton?
    fileprivate var horizontalInset:CGFloat = 50
    fileprivate var blurEffectView:UIVisualEffectView?
    fileprivate var backdropView:UIView?
    open var hasShown:Bool = false
    
    // Colors
    fileprivate var buttonBackgroundColor: UIColor {
        get {
            return UIColor.black.withAlphaComponent(0.2)
        }
    }
    fileprivate var buttonTextColor: UIColor {
        get {
            return self.style == .dark ? UIColor.white : UIColor.black.withAlphaComponent(0.8)
        }
    }
    
    fileprivate var buttonHighlightedTextColor: UIColor {
        get {
            return self.style == .dark ? UIColor.black.withAlphaComponent(0.8) : UIColor.white
        }
    }
    
    // Alert vars
    open var message: String?
    open fileprivate(set) var actions: [TVAlertAction] = []
    open fileprivate(set) var textFields: [UITextField]?
    fileprivate var buttons: [UIButton] = []
    open var style: UIBlurEffectStyle = .dark
    
    open var preferredAction: TVAlertAction?
    open fileprivate(set) var preferredStyle: UIAlertControllerStyle = .alert
    
    // Customizations
    open var autoDismiss:Bool = true
    open var manageKeyboard:Bool = true
    open var autosortActions:Bool = true
    open var buttonShadows:Bool = true
    
    public convenience init(title: String?, message: String?, preferredStyle: UIAlertControllerStyle) {
        self.init()
        
        self.title = title
        self.message = message
        self.preferredStyle = preferredStyle
        
        self.modalPresentationStyle = .overCurrentContext;
        self.modalTransitionStyle = .crossDissolve
        self.view.backgroundColor = UIColor.clear
    }
    
    //MARK: View setup
    open override func loadView() {
        if let window = UIApplication.shared.keyWindow {
            self.view = UIView(frame: window.bounds)
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setupBlurView()
        self.blurEffectView?.effect = nil
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupContentView()
        self.setupObservers()
        
        // Show animations
        if self.hasShown == false {
            self.hasShown = true
            
            self.view.alpha = 0
            self.contentView?.alpha = 0
            
            self.animate(duration: 0.08, animations: {
                
                self.view.alpha = 1
                
            }, completion: { (completed) in
                
                self.animate(duration: 0.45, curve: .easeOut, animations: {
                    self.blurEffectView?.effect = UIBlurEffect(style: self.style)
                    self.backdropView?.alpha = 0
                })
                
            })
            
            self.animate(duration: 0.7, curve: .easeOut, animations: {
                
                self.contentView?.alpha = 1
                
            })
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        self.removeObservers()
        super.viewWillDisappear(animated)
    }
    
    //MARK: Elements
    open func addAction(_ action: TVAlertAction) {
        action.delegate = self
        self.actions += [action]
    }
    
    open func addTextField(_ configurationHandler: ((UITextField) -> Void)?) {
        
        func configureTextField(_ t:UITextField) {
            let color = UIColor.black.withAlphaComponent(0.75)
            t.backgroundColor = self.style == .dark ? UIColor.white.withAlphaComponent(0.75) :UIColor.black.withAlphaComponent(0.09)
            t.textColor = color
            t.tintColor = color
            t.layer.cornerRadius = 5
        }
        
        if self.textFields == nil {
            self.textFields = []
        }
        
        let t = TVATextField()
        self.textFields! += [t]
        configureTextField(t)
        if let c = configurationHandler {
            c(t)
        }
    }

    //MARK: Rotation
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {

        if let mask = self.parent?.supportedInterfaceOrientations {
            return mask
        }
        return .all
    }

    override open var shouldAutorotate : Bool {
        if let rotate = self.parent?.shouldAutorotate {
            return rotate
        }
        return true
    }
}

// MARK: - Touch interactions
extension TVAlertController {
    
    @objc fileprivate func didTapButton(_ sender:UIButton) {
        let a = self.actions[sender.tag]
        if self.autoDismiss {
            
            animate(duration: 0.33, animations: {
                self.blurEffectView?.effect = nil
                self.blurEffectView?.alpha = 0
                self.contentView?.alpha = 0
            }, completion: { (completed) in
                self.dismiss(animated: false) {
                    a.handler?(a)
                }
            }) 
        } else {
            a.handler?(a)
        }
    }
    
    fileprivate func closeKeyboard() {
        self.view.endEditing(true)
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.firstButtonTouched = nil
        self.processButtonStates(touches, withEvent: event) { b, inside in
            if inside {
                self.firstButtonTouched = b
                if b.isEnabled {
                    b.sendActions(for: .touchDown)
                }
            }
        }
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.processButtonStates(touches, withEvent: event) { b, inside in
            if b.isEnabled == false || self.firstButtonTouched == nil {
                b.isHighlighted = false
                return
            }
            if inside {
                b.sendActions(for: .touchDragEnter)
            } else {
                b.sendActions(for: .touchDragExit)
            }
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.processButtonStates(touches, withEvent: event) { b, inside in
            b.isHighlighted = false
            if inside && b.isEnabled && self.firstButtonTouched != nil {
                
                b.sendActions(for: .touchUpInside)
            }
            self.closeKeyboard()
        }
    }
    
    fileprivate func processButtonStates(_ touches: Set<UITouch>, withEvent event: UIEvent?, eventHandler:((UIButton, Bool)->Void)? = nil) {
        for t in touches {
            let point = t.location(in: self.contentView)
            
            for b in self.buttons {
                if let testPoint = self.contentView?.convert(point, to: b) {
                    let inside = b.point(inside: testPoint, with:event)
                    b.isHighlighted = inside
                    eventHandler?(b, inside)
                }
            }
        }
    }
}

// MARK: - Setup
private extension TVAlertController {
    
    func setupContentView() {
        
        if self.contentView == nil {
            
            var views = [UIView]()
            let contentView = UIView()
            self.view.addSubview(contentView)
            
            contentView.translatesAutoresizingMaskIntoConstraints = false
            contentView.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
            contentView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
            
            // Vertical Constraints
            self.contentView = contentView
            
            self.sortButtons()
            self.setupLabels(&views)
            self.setupTextFields(&views)
            self.setupButtons(&views)
            self.setupConstraints(&views)
            
            contentView.layoutIfNeeded()
            contentView.sizeToFit()
            
            let height = abs((views.first?.frame.minY ?? 0) - (views.last?.frame.maxY ?? 0))
            
            contentView.centerVerticallyInSuperview()
            contentView.centerHorizontallyInSuperview()
            contentView.constrainSizeTo(CGSize(width: self.view.bounds.width - (self.horizontalInset * 2), height: height))
            
            
            contentView.layoutIfNeeded()
            
            for b in self.buttons {
                b.layoutSubviews()
            }
        }
    }
    
    func sortButtons() {
        
        if self.autosortActions == false {
            return
        }
        
        let normal = self.actions.filter({$0.style != .cancel})
        let cancel = self.actions.filter({$0.style == .cancel})
        var actions = normal
        actions.append(contentsOf: cancel)
        if self.actions.count == 2 {
            actions = cancel
            actions.append(contentsOf: normal)
        }
        self.actions = actions
    }
    
    func setupLabels(_ views:inout [UIView]) {
        
        func configureLabel(_ label:UILabel) {
            label.textAlignment = .center
            label.numberOfLines = 0
            label.lineBreakMode = NSLineBreakMode.byWordWrapping
            label.textColor = self.buttonTextColor
        }
        
        if let t = self.title {
            let titleView = TVALabel()
            titleView.text = t
            titleView.font = UIFont.boldSystemFont(ofSize: 18)
            configureLabel(titleView)
            views += [titleView]
        }
        
        if let m = self.message {
            let messageView = TVALabel()
            messageView.text = m
            messageView.font = UIFont.systemFont(ofSize: 16)
            configureLabel(messageView)
            views += [messageView]
        }
        
    }
    
    func setupTextFields(_ views:inout [UIView]) {
        
        guard let textFields = self.textFields else {
            return
        }
        
        for (_, textfield) in textFields.enumerated() {
            views += [textfield]
        }
    }
    
    func setupButtons(_ views:inout [UIView]) {
        
        func configureButton(_ button:TVAButton, action:TVAlertAction) {
            button.setTitle(action.title, for: UIControlState())
            button.isEnabled = action.isEnabled
            button.translatesAutoresizingMaskIntoConstraints = false
            button.isUserInteractionEnabled = false
            button.layer.cornerRadius = 5
            button.shadows = self.buttonShadows
            button.addTarget(self, action: #selector(TVAlertController.didTapButton(_:)), for: .touchUpInside)
            var buttonTextColor = self.buttonTextColor
            switch action.style {
            case .default:
                break
            case .cancel:
                if self.preferredAction == nil {
                    button.titleLabel?.font = UIFont.boldSystemFont(ofSize: button.titleLabel!.font.pointSize)
                }
                break
            case .destructive:
                buttonTextColor = UIColor.red
                break
            }
            
            if let a = self.preferredAction, a == action {
                button.titleLabel?.font = UIFont.boldSystemFont(ofSize: button.titleLabel!.font.pointSize)
            }
            
            button.setTitleColor(buttonTextColor, for: UIControlState())
            button.setTitleColor(self.buttonHighlightedTextColor, for: .highlighted)
            button.setBackgroundColor(self.buttonBackgroundColor, forState: UIControlState())
            button.setBackgroundColor(buttonTextColor, forState: .highlighted)
        }
        
        var containerView:UIView? = nil
        let count = self.actions.count
        
        for (i, action) in self.actions.enumerated() {
            let button = TVAButton(type: .custom)
            self.buttons += [button]
            button.tag = i
            configureButton(button, action: action)
            if count == 2 {
                if containerView == nil {
                    let c = UIView()
                    containerView = c
                    views += [c]
                }
                containerView?.addSubview(button)
            } else {
                views += [button]
            }
        }
        self.setupPairedConstraintsIfNeeded(containerView)
    }
    
    func setupPairedConstraintsIfNeeded(_ containerView:UIView?) {
        if let c = containerView, self.buttons.count == 2 {
            c.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[button0]-20-[button1]|", options:[.alignAllCenterY, .alignAllBottom, .alignAllTop], metrics: nil, views: ["button0":self.buttons[0],"button1":self.buttons[1]]))
            c.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[button0]|", options:[.alignAllBottom, .alignAllTop], metrics: nil, views: ["button0":self.buttons[0],"button1":self.buttons[1]]))
            c.addConstraint(NSLayoutConstraint(item: self.buttons[0], attribute: .width, relatedBy: .equal, toItem: self.buttons[1], attribute: .width, multiplier: 1, constant: 0))
        }
    }
    
    func setupConstraints(_ views:inout [UIView]) {
        
        if views.count < 1 {
            return
        }
        
        var verticalString = "V:"
        var dict:[String:AnyObject] = [:]
        let limit = views.count - 1
        var index = 0
        var prev:UIView?
        
        for (i,v) in views.enumerated() {
            
            let name = "view\(i)"
            dict[name] = v
            
            v.translatesAutoresizingMaskIntoConstraints = false
            v.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
            v.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
            self.contentView?.addSubview(v)
            
            var spacing:CGFloat = 10
            var height:CGFloat = 36
            
            if v is UIButton {
                spacing = 15
            }
            
            if let label = v as? UILabel {
                
                let maxWidth = self.view.bounds.width - (self.horizontalInset * 2)
                let maxHeight : CGFloat = 10000
                height = label.attributedText?.boundingRect(with: CGSize(width: maxWidth, height: maxHeight), options: .usesLineFragmentOrigin, context: nil).size.height ?? 30
            }
            
            if prev != nil {
                verticalString += "-\(spacing)-"
            }
            
            verticalString += "[\(name)]"
            
            if index == limit {
                verticalString += "|"
            }
            
            v.centerHorizontallyInSuperview()
            v.constrainSizeToHeight(height)
            
            index += 1
            prev = v
        }
        
        // Vertical Constraints
        self.contentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: verticalString, options:[.alignAllLeft, .alignAllRight], metrics: nil, views: dict))
        
        self.contentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view0]|", options:[], metrics: nil, views: dict))
    }
    
}

// MARK: - TVAlertActionDelegate
extension TVAlertController: TVAlertActionDelegate {
    
    fileprivate func didChangeEnabled(_ action:TVAlertAction, enabled: Bool) {
        
        let index = (self.actions as NSArray).index(of: action)
        self.buttons[index].isEnabled = enabled
        
    }
}

// MARK: - Blur view + backdrop helper
private extension TVAlertController {
    func setupBlurView() {
        
        self.setupBackdropView()
        
        if self.blurEffectView != nil {
            return
        }
        
        let blurEffect = UIBlurEffect(style: self.style)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.frame = self.view.bounds
        view.addSubview(blurredEffectView)
        self.blurEffectView = blurredEffectView
        blurredEffectView.constrainToSuperviewEdges()

        view.constrainToSuperviewEdges()
    }
    
    func setupBackdropView() {
        if #available(iOS 10, *) {
            if self.backdropView != nil {
                return
            }
            let backdropView = UIView(frame: self.view.bounds)
            backdropView.backgroundColor = self.style == .dark ? UIColor.black : UIColor.white
            backdropView.alpha = self.style == .dark ? 0.3 : 0.6
            view.addSubview(backdropView)
            view.constrainToSuperviewEdges()
            self.backdropView = backdropView
        }
    }
}

// MARK:- Keyboard moving
private extension TVAlertController {
    
    func setupObservers() {
        
        if self.manageKeyboard {
            return
        }
        NotificationCenter.default.addObserver(self, selector:#selector(TVAlertController.keyboardWillAppear(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(TVAlertController.keyboardWillDisappear(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillAppear(_ notification: Notification){
        self.animateContentViewYCenterTo(-30)
    }
    
    @objc func keyboardWillDisappear(_ notification: Notification){
        self.animateContentViewYCenterTo(0)
    }
    
    func animateContentViewYCenterTo(_ y:CGFloat) {
        
        guard let contentView = self.contentView else {
            return
        }
        
        for c in self.view.constraints {
            if c.firstItem as! NSObject == contentView && c.firstAttribute == NSLayoutAttribute.centerY {
                c.constant = y
            }
        }
        
        UIView.animate(withDuration: 0.33, animations: {
            self.view.layoutIfNeeded()
        }) 
    }
}

// MARK:- External Extensions

// MARK: First responder
private extension UIView {
    func findFirstResponder() -> UIView? {
        for subView in self.subviews {
            if subView.isFirstResponder {
                return subView
            }
            
            if let recursiveSubView = subView.findFirstResponder() {
                return recursiveSubView
            }
        }
        
        return nil
    }
}

// MARK: AutoLayout helpers
private extension UIView {
    
    func centerInSuperview() {
        self.centerHorizontallyInSuperview()
        self.centerVerticallyInSuperview()
    }
    
    func centerHorizontallyInSuperview() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.superview?.addConstraint(NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: self.superview, attribute: .centerX, multiplier: 1, constant: 0))
    }
    
    func centerVerticallyInSuperview() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.superview?.addConstraint(NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: self.superview, attribute: .centerY, multiplier: 1, constant: 0))
    }
    
    func constrainSizeTo(_ size:CGSize) {
        self.constrainSizeToWidth(size.width)
        self.constrainSizeToHeight(size.height)
    }
    
    func constrainSizeToHeight(_ size:CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: size))
    }
    
    func constrainSizeToWidth(_ size:CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: size))
    }
    
    func constrainToSuperviewEdges() {

        if let superview = self.superview {
            self.translatesAutoresizingMaskIntoConstraints = false
            let edges:[NSLayoutAttribute] = [.top, .bottom, .left, .right]

            for edge in edges {
                superview.addConstraint(NSLayoutConstraint(item: superview, attribute: edge, relatedBy: .equal, toItem: self, attribute: edge, multiplier: 1, constant: 0))
            }
        }
    }

}

// MARK: Image with color -- for button background
private extension UIImage {
    static func imageWithColor(_ color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

// MARK:- TVButton
private class TVAButton:UIButton {
    
    var shadows:Bool = true
    fileprivate var backgroundColorStates:[String:UIColor] = [:]
    override var isEnabled: Bool {
        didSet {
            self.alpha = isEnabled ? 1 : 0.3
        }
    }
    
    override var backgroundColor: UIColor? {
        didSet {
            self.backgroundColorStates["\(UIControlState())"] = self.backgroundColor ?? UIColor.clear
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            let state = self.isHighlighted ? UIControlState.highlighted : UIControlState()
            if let c = self.backgroundColorStates["\(state)"] {
                self.layer.backgroundColor = c.cgColor
            }
            self.layer.shadowColor = self.isHighlighted ? UIColor.black.cgColor : UIColor.clear.cgColor
            self.layer.shadowRadius = 4;
            self.layer.shadowOpacity = 0.7;
            self.layer.shadowOffset = CGSize(width: 0, height: 2);
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    fileprivate func commonInit() {
        
        self.addTarget(self, action: #selector(TVAButton.grow), for: .touchDown)
        self.addTarget(self, action: #selector(TVAButton.grow), for: .touchDragEnter)
        self.addTarget(self, action: #selector(TVAButton.normal), for: .touchDragExit)
        self.addTarget(self, action: #selector(TVAButton.normal), for: .touchUpInside)
    }
    
    @objc fileprivate func grow() {
        self.transformToSize(1.15)
    }
    
    @objc fileprivate func normal() {
        self.transformToSize(1.0)
    }
    
    @objc fileprivate func shrink() {
        self.transformToSize(0.8)
    }
    
    fileprivate func transformToSize(_ scale:CGFloat) {
        UIView.beginAnimations("button", context: nil)
        UIView.setAnimationDuration(0.1)
        self.transform = CGAffineTransform(scaleX: scale,y: scale);
        UIView.commitAnimations()
    }
    
    func setBackgroundColor(_ color: UIColor, forState state: UIControlState) {
        self.backgroundColorStates["\(state)"] = color
        
        if state == UIControlState() {
            self.backgroundColor = color
        }
    }
}

// MARK:- TVTextField
private class TVATextField: UITextField {
    let inset: CGFloat = 10
    
    // placeholder position
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: inset , dy: inset)
    }
    
    // text position
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: inset , dy: inset)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: inset, dy: inset)
    }
}

// MARK:- TVLabel
private class TVALabel: UILabel {
    
    fileprivate override func layoutSubviews() {
        super.layoutSubviews()
        self.preferredMaxLayoutWidth = self.bounds.width
        super.layoutSubviews()
    }
}


// MARK:- Animation Helper
extension TVAlertController {
    
    fileprivate func animate(duration:TimeInterval, curve:UIViewAnimationCurve = .linear, animations:@escaping ()->Void, completion:((_:Bool)->Void)? = nil) {
    
    
        if #available(iOS 10.0, *) {
            let animator = UIViewPropertyAnimator(duration: duration, curve: curve, animations: animations)
            animator.startAnimation()
            
            if let completion = completion {
                animator.addCompletion({ (position) in
                    completion(position == .end)
                })
            }
            
        } else {
            
            if let completion = completion {
                UIView.animate(withDuration: duration, animations: animations, completion: completion)
            } else {
                UIView.animate(withDuration: duration, animations: animations)
            }
        }
    }
}
