//
//  SIMChatViewController.swift
//  SIMChat
//
//  Created by sagesse on 9/19/15.
//  Copyright © 2015 Sagesse. All rights reserved.
//

import UIKit

class SIMChatViewController: SIMViewController {
    /// 构建
    override func build() {
        super.build()
        
        // 聊天内容
        self.registerClass(SIMChatCellText.self,    SIMChatContentText.self)
        self.registerClass(SIMChatCellAudio.self,   SIMChatContentAudio.self)
        self.registerClass(SIMChatCellImage.self,   SIMChatContentImage.self)
        // 辅助
        self.registerClass(SIMChatCellTips.self,    SIMChatContentTips.self)
        self.registerClass(SIMChatCellDate.self,    SIMChatContentDate.self)
        // 默认
        self.registerClass(SIMChatCellUnknow.self,  SIMChatContentUnknow.self)
        
        // 测试会话
        if true {
            let s = SIMChatUser(identifier: "self", name: "self", gender: 1, portrait: nil)
            let o = SIMChatUser(identifier: "other", name: "other", gender: 2)
            let c = SIMChatConversation(recver: o, sender: s)
            
            self.conversation = c
        }
    }
    /// 加载完成
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let vs = ["tf" : textField]
        
        // 设置背景
        view.backgroundColor = UIColor.clearColor()
        view.layer.contents =  SIMChatImageManager.defaultBackground?.CGImage
        view.layer.contentsGravity = kCAGravityResizeAspectFill//kCAGravityResize
        view.layer.masksToBounds = true
        // inputViewEx使用al
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = UIColor(hex: 0xEBECEE)
        textField.delegate = self
        // tableView使用am
        tableView.frame = view.bounds
        tableView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.backgroundColor = UIColor.clearColor()
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = true
        tableView.rowHeight = 32
        tableView.dataSource = self
        tableView.delegate = self
        
        // add views
        // 第一个视图必须是tableView, addSubview(tableView)在ios7下有点bug?
        view.insertSubview(tableView, atIndex: 0)
        view.insertSubview(textField, aboveSubview: tableView)
        
        // add constraints
        view.addConstraints(NSLayoutConstraintMake("H:|-(0)-[tf]-(0)-|", views: vs))
        view.addConstraints(NSLayoutConstraintMake("V:[tf]|", views: vs))
        
        // add event
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "resignFirstResponder"))
        
        // 加载聊天历史
        dispatch_async(dispatch_get_main_queue()) {
            self.loadHistorys(40)
        }
    }
    /// 视图将要出现
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // add kvos
        let center = NSNotificationCenter.defaultCenter()
        
        center.addObserver(self, selector: "onKeyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: "onKeyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    /// 视图将要消失
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        let center = NSNotificationCenter.defaultCenter()
        
        center.removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        center.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    /// 放弃编辑
    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
    /// 最新的消息
    var latest: SIMChatMessage?
    /// 会话
    var conversation: SIMChatConversation! {
        willSet { self.conversation?.delegate = nil }
        didSet  { self.conversation?.delegate = self }
    }
    
    private(set) lazy var tableView = UITableView()
    private(set) lazy var textField = SIMChatTextField(frame: CGRectZero)
  
    /// 数据源
    internal lazy var source = Array<SIMChatMessage>()
    
    /// 单元格
    internal lazy var testers = Dictionary<String, SIMChatCell>()
    internal lazy var relations = Dictionary<String, SIMChatCell.Type>()
    internal lazy var relationDefault = NSStringFromClass(SIMChatCellUnknow.self)
    
    /// 自定义键盘
    internal lazy var keyboard = UIView?()
    internal lazy var keyboards = Dictionary<SIMChatTextFieldItemStyle, UIView>()
    internal lazy var keyboardHeight =  CGFloat(0)
    internal lazy var keyboardHiddenAnimation = false
}

/// MARK: - /// Content
extension SIMChatViewController : UITableViewDataSource {
    /// 行数
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source.count
    }
    /// 获取每一行的高度
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // 获取数据
        let message = source[indexPath.row]
        let key: String = {
            if message.content != nil {
                let type = NSStringFromClass(message.content!.dynamicType)
                if self.relations[type] != nil {
                    return type
                }
            }
            return self.relationDefault
        }()
        // 己经计算过了?
        if message.height != 0 {
            return message.height
        }
        // 获取测试单元格
        let cell = testers[key] ?? {
            let tmp = tableView.dequeueReusableCellWithIdentifier(key) as! SIMChatCell
            // 隐藏
            tmp.hidden = true
            tmp.enabled = false
            // 缓存
            self.testers[key] = tmp
            // 创建完成
            return tmp
        }()
        // 预更新大小
        cell.frame = CGRectMake(0, 0, tableView.bounds.width, tableView.rowHeight)
        // 加载数据
        cell.reloadData(message, ofUser: self.conversation.sender)
        // 计算高度
        message.height = cell.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        // 检查结果
        SIMLog.debug("\(key): \(message.height)")
        // ok
        return message.height
    }
    ///
    /// 加载单元格
    ///
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // 获取数据
        let message = source[indexPath.row]
        let key: String = {
            if message.content != nil {
                let type = NSStringFromClass(message.content!.dynamicType)
                if self.relations[type] != nil {
                    return type
                }
            }
            return self.relationDefault
        }()
        // 获取单元格, 如果不存在则创建
        let cell = tableView.dequeueReusableCellWithIdentifier(key, forIndexPath: indexPath) as! SIMChatCell
        // 重新加载数据
        //cell.delegate = self
        cell.reloadData(message, ofUser: self.conversation.sender)
        // 完成.
        return cell
    }
}

/// MARK: - /// Content Event
extension SIMChatViewController : UITableViewDelegate {
    /// 开始拖动
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if scrollView === tableView && textField.selectedStyle != .None {
            self.resignFirstResponder()
        }
    }
    ///
    /// 将要结束拖动
    ///
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        //Log.debug(targetContentOffset.memory)
//        
//        let pt = scrollView.contentOffset
//        
//        //Log.debug("\(pt.y) \(targetContentOffset.memory.y)")
//        if pt.y < -scrollView.contentInset.top && targetContentOffset.memory.y <= -scrollView.contentInset.top {
//            dispatch_async(dispatch_get_main_queue()) {
//                //self.loadMore(nil)
//            }
//        }
    }
    /// 结束减速
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if scrollView === tableView && scrollView.contentOffset.y <= -scrollView.contentInset.top {
//            // 查询.
//            self.conversation.query(40, last: self.lastMessage) { [weak self]ms, e in
//                // 查询成功?
//                if let ms = ms as? [SIMChatMessage] {
//                    // 没有更多了
//                    if ms.count == 0 {
//                        return
//                    }
//                    // 还有继续插入
//                    self?.insertMessages(ms.reverse(), atIndex: 0, animated: true)
//                    self?.latest = ms.last
//                }
//            }
        }
    }
}

/// MARK: - /// Text Field
extension SIMChatViewController : SIMChatTextFieldDelegate {
    /// 选中..
    func chatTextField(chatTextField: SIMChatTextField, didSelectItem item: Int) {
        SIMLog.trace()
        if let style = SIMChatTextFieldItemStyle(rawValue: item) {
            self.updateKeyboard(style: style)
        }
    }
    /// ...
    func chatTextFieldContentSizeDidChange(chatTextField: SIMChatTextField) {
        // 填充动画更新
        UIView.animateWithDuration(0.25) {
            // 更新键盘高度
            self.view.layoutIfNeeded()
            self.updateKeyboard(height: self.keyboardHeight)
        }
    }
    /// ok
    func chatTextFieldShouldReturn(chatTextField: SIMChatTextField) -> Bool {
        // 发送.
        if let text = textField.text where !text.isEmpty {
            self.send(text: text)
            self.textField.text = nil
        }
        // 不可能return
        return false
    }
}

