//
//  SIMChatInputPanel+Face.swift
//  SIMChat
//
//  Created by sagesse on 1/22/16.
//  Copyright © 2016 Sagesse. All rights reserved.
//

import UIKit

// TODO: 内部设计有点混乱/不太合理, 有时间需要重构一下
// TODO: 暂未支持横屏

@objc public protocol SIMChatInputPanelDelegateFace: SIMChatInputPanelDelegate {
    
    optional func inputPanel(inputPanel: UIView, shouldSelectFace face: String) -> Bool
    optional func inputPanel(inputPanel: UIView, didSelectFace face: String)
    
    optional func inputPanelShouldReturn(inputPanel: UIView) -> Bool
    optional func inputPanelShouldSelectBackspace(inputPanel: UIView) -> Bool
}

extension SIMChatInputPanel {
    public class Face: UIView {
        public override init(frame: CGRect) {
            super.init(frame: frame)
            build()
        }
        public required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            build()
        }
        
        public weak var delegate: SIMChatInputPanelDelegateFace?
        
        private lazy var _tabBar: TabBar = {
            let view = TabBar()
            view.backgroundColor = UIColor(rgb: 0xF8F8F8)
            return view
        }()
        private lazy var _preview: Preview = {
            let view = Preview()
            view.frame = CGRectMake(0, 0, 80, 80)
            view.hidden = true
            return view
        }()
        private lazy var _pageControl: PageControl = {
            let view = PageControl()
            view.numberOfPages = 8
            view.pageIndicatorTintColor = UIColor.grayColor()
            view.currentPageIndicatorTintColor = UIColor.darkGrayColor()
            return view
        }()
        private lazy var _contentView: ContentView = {
            let view = ContentView()
            view.showsHorizontalScrollIndicator = false
            view.showsVerticalScrollIndicator = false
            view.pagingEnabled = true
            view.dataSource = self
            view.delegate = self
            view.backgroundColor = UIColor.whiteColor()
            
            view.registerClass(Page.Classic.self, forCellWithReuseIdentifier: NSStringFromClass(Model.Classic.self))
            
            return view
        }()
        
        // face己经支持, 但聊天页面还没有支持, 暂不使用
        //private lazy var _pages: [AnyObject] = Model.Classic.emojis().reverse() + Model.Classic.faces()
        private lazy var _pages: [AnyObject] = Model.Classic.emojis()
        
        private struct Page {}
        private struct Model {}
    }
}

extension SIMChatInputPanel.Face {
    private class TabBar: UIScrollView {
        override func intrinsicContentSize() -> CGSize {
            return CGSizeMake(bounds.width, 37)
        }
    }
    private class PageControl: UIPageControl {
        override func intrinsicContentSize() -> CGSize {
            return CGSizeMake(bounds.width, 25)
        }
    }
    private class ContentView: UICollectionView {
        init() {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .Horizontal
            layout.sectionInset = UIEdgeInsetsZero
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
            super.init(frame: CGRectZero, collectionViewLayout: layout)
            
            registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "Unknow")
        }
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        override func registerClass(cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
            super.registerClass(cellClass, forCellWithReuseIdentifier: identifier)
            cellClasses[identifier] = cellClass
        }
        
        private var cellClasses: [String: AnyClass] = [:]
    }
    private class Preview: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            build()
        }
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            build()
        }
        private func build() {
            layer.contents = SIMChatImageManager.images_face_preview?.CGImage
            

        }
        
        var value: String? {
            didSet {
                guard value != oldValue else {
                    return
                }
                if let value: NSString = value {
                    if value.length <= 2 {
                        label.text = value as String
                        label.frame = bounds
                        label.sizeToFit()
                        label.frame = CGRectMake(
                            (bounds.width - label.bounds.width) / 2,
                            (bounds.height - label.bounds.height) / 2 - 4,
                            label.bounds.width,
                            label.bounds.height)
                        if label.superview != self {
                            addSubview(label)
                        }
                        imageView.removeFromSuperview()
                    } else if value.hasPrefix("qq:") {
                        guard let image = UIImage(named: "SIMChat.bundle/Face/\(value.substringFromIndex(3))") else {
                            return
                        }
                        imageView.image = image
                        imageView.frame = CGRectMake(
                            (bounds.width - image.size.width) / 2,
                            (bounds.height - image.size.height) / 2 - 4,
                            image.size.width,
                            image.size.height)
                        if imageView.superview != self {
                            addSubview(imageView)
                        }
                        label.removeFromSuperview()
                    }
                    
                } else {
                    label.removeFromSuperview()
                    imageView.removeFromSuperview()
                }
            }
        }
        
        lazy var label: UILabel = {
            let view = UILabel()
            view.font = UIFont.systemFontOfSize(32)
            return view
        }()
        lazy var imageView: UIImageView = {
            let view = UIImageView()
            return view
        }()
    }
}

// MARK: - Content Page -> Classic

extension SIMChatInputPanel.Face.Page {
    /// 经典类型
    private class Classic: UICollectionViewCell, UIGestureRecognizerDelegate {
        override init(frame: CGRect) {
            super.init(frame: frame)
            build()
        }
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            build()
        }
        
        private func build() {
            let tap = UITapGestureRecognizer(target: self, action: "onItemPress:")
            tap.delegate = self
            gestureRecognizer.delegate = self
            
            contentView.addGestureRecognizer(tap)
            contentView.addGestureRecognizer(gestureRecognizer)
        }
        
        /// 代理
        weak var delegate: SIMChatInputPanelDelegateFaceOfClassic?
        /// 对应的模型
        var model: SIMChatInputPanel.Face.Model.Classic? {
            didSet {
                guard model !== oldValue else {
                    return
                }
                setNeedsDisplay()
                gestureRecognizer.enabled = !(model?.value.isEmpty ?? true)
            }
        }
        
        var maximumItemCount: Int = 7
        var maximumLineCount: Int = 3
        
        var contentInset: UIEdgeInsets = UIEdgeInsetsMake(12, 10, 42, 10)
        weak var preview: SIMChatInputPanel.Face.Preview?
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            let size = itemSize
            var frame = CGRectZero
            
            frame.origin.x = contentInset.left + CGFloat(maximumItemCount - 1) * size.width
            frame.origin.y = contentInset.top + CGFloat(maximumLineCount - 1) * size.height
            frame.size.width = size.width
            frame.size.height = size.height
            
            backspaceButton.frame = frame
            
            if backspaceButton.superview != contentView {
                contentView.addSubview(backspaceButton)
            }
        }
        override func drawRect(rect: CGRect) {
            
            let size = itemSize
            let config = [
                NSFontAttributeName: UIFont.systemFontOfSize(32)
            ]
            
            for row in 0 ..< maximumLineCount {
                for col in 0 ..< maximumItemCount {
                    let index = row * maximumItemCount + col
                    guard index < model?.value.count else {
                        continue
                    }
                    guard let value: NSString = model?.value[index] else {
                        continue
                    }
                    
                    if value.length <= 2 {
                        var frame = CGRectZero
                        
                        frame.origin.x = contentInset.left + CGFloat(col) * size.width
                        frame.origin.y = contentInset.top + CGFloat(row) * size.height
                        
                        frame.size = value.sizeWithAttributes(config)
                        frame.origin.x += (size.width - frame.size.width) / 2
                        frame.origin.y += (size.height - frame.size.height) / 2
                        
                        value.drawInRect(frame, withAttributes: config)
                    } else if value.hasPrefix("qq:") {
                        guard let image = UIImage(named: "SIMChat.bundle/Face/\(value.substringFromIndex(3))") else {
                            continue
                        }
                        var frame = CGRectZero
                        
                        frame.origin.x = contentInset.left + CGFloat(col) * size.width
                        frame.origin.y = contentInset.top + CGFloat(row) * size.height
                        
                        frame.size = image.size
                        frame.origin.x += (size.width - frame.size.width) / 2
                        frame.origin.y += (size.height - frame.size.height) / 2
                        
                        image.drawInRect(frame)
                    }
                }
            }
        }
        
        func indexAtPoint(pt: CGPoint) -> Int? {
            let x = pt.x - contentInset.left
            let y = pt.y - contentInset.right
            let width = bounds.width - contentInset.left - contentInset.right
            let height = bounds.height - contentInset.top - contentInset.bottom
            let size = itemSize
            guard x >= 0 && x <= width && y >= 0 && y <= height else {
                return nil
            }
            let row = Int(y / size.height)
            let column = Int(x / size.width)
            return row * maximumItemCount + column
        }
        
        /// 点击事件
        dynamic func onItemPress(sender: UITapGestureRecognizer) {
            guard sender.state == .Ended else {
                return
            }
            guard let index = indexAtPoint(sender.locationInView(self)) where index < model?.value.count else {
                return
            }
            guard let item = model?.value[index] else {
                return
            }
            SIMLog.trace("index: \(index), value: \(item)")
            if delegate?.classic?(self, shouldSelectItem: item) ?? true {
                delegate?.classic?(self, didSelectItem: item)
            }
        }
        /// 长按事件
        dynamic func onItemLongPress(sender: UILongPressGestureRecognizer) {
            guard let preview = self.preview else {
                return
            }
            let pt = sender.locationInView(self)
            // 开始的时候, 计算一下选择的是那一个.
            if sender.state == .Began {
                guard let index = indexAtPoint(pt) where index < model?.value.count else {
                    return
                }
                guard let item = model?.value[index] else {
                    return
                }
                
                let size = itemSize
                let row = index / maximumItemCount
                let column = index % maximumItemCount
                
                SIMLog.trace("index: \(index), value: \(item)")
                
                selectedPoint = CGPointMake(
                    contentInset.left + CGFloat(column) * size.width,
                    contentInset.top + CGFloat(row) * size.height)
                
                preview.value = model?.value[index]
                preview.hidden = false
            }
            /// 事件结束的时候检查区域
            if sender.state == .Ended || sender.state == .Cancelled || sender.state == .Failed {
                guard let selected = selectedPoint else {
                    return
                }
                guard let item = preview.value, let index = model?.value.indexOf(item) else {
                    preview.hidden = true
                    return
                }
                
                // 计算距离, sqr(x^2 + y^2)
                let distance = fabs(sqrt(pow(preview.frame.midX - selected.x, 2) + pow(preview.frame.maxY - selected.y, 2)))
                let size = itemSize
                
                SIMLog.trace("index: \(index), value: \(item), distance: \(Int(distance))")
                // 只有正常结束的时候少有效
                if sender.state == .Ended && CGRectMake(selected.x, selected.y, size.width, size.height).contains(pt) {
                    if delegate?.classic?(self, shouldSelectItem: item) ?? true {
                        delegate?.classic?(self, didSelectItem: item)
                    }
                }
                
                UIView.animateWithDuration(0.25 * max(Double(distance / 100), 1),
                    animations: {
                        var frame = preview.frame
                        frame.origin.x = (selected.x + size.width / 2) - frame.width / 2
                        frame.origin.y = (selected.y + 12) - frame.height
                        preview.frame = frame
                    },
                    completion: { b in
                        preview.hidden = true
                    })
                selectedPoint = nil
            }
            if selectedPoint != nil {
                var frame = preview.frame
                frame.origin.x = pt.x - frame.width / 2
                frame.origin.y = pt.y - frame.height
                preview.frame = frame
            }
        }
        /// 删除事件
        dynamic func onBackspacePress(sender: AnyObject) {
            SIMLog.trace()
            if delegate?.classicShouldSelectBackspace?(self) ?? true {
                delegate?.classicDidSelectBackspace?(self)
            }
        }
        
        
        @objc override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
            let pt = gestureRecognizer.locationInView(contentView)
            // 在区域内
            let x = contentInset.left
            let y = contentInset.right
            let width = bounds.width - contentInset.left - contentInset.right
            let height = bounds.height - contentInset.top - contentInset.bottom
            if !CGRectMake(x, y, width, height).contains(pt) {
                return false
            }
            return !backspaceButton.frame.contains(pt)
        }
       
        private var selectedPoint: CGPoint?
        private var itemSize: CGSize {
            let width = bounds.width - contentInset.left - contentInset.right
            let height = bounds.height - contentInset.top - contentInset.bottom
            return CGSizeMake(width / CGFloat(maximumItemCount), height / CGFloat(maximumLineCount))
        }
        lazy var backspaceButton: UIButton = {
            let view = UIButton()
            view.addTarget(self, action: "onBackspacePress:", forControlEvents: .TouchUpInside)
            
            view.setImage(SIMChatImageManager.images_face_delete_nor, forState: .Normal)
            view.setImage(SIMChatImageManager.images_face_delete_press, forState: .Highlighted)
            return view
        }()
        private lazy var gestureRecognizer: UIGestureRecognizer = {
            let recognzer = UILongPressGestureRecognizer(target: self, action: "onItemLongPress:")
            recognzer.minimumPressDuration = 0.25
            return recognzer
        }()
    }
}

// MARK: - Content Model
extension SIMChatInputPanel.Face.Model {
    /// 经典类型
    private class Classic {
        init(_ value: [String]) {
            self.value = value
        }
        
        var value: [String] = []
        
        static func faces() -> [Classic] {
            let root = NSBundle.mainBundle().resourceURL
            guard let url = root?.URLByAppendingPathComponent("SIMChat.bundle/Preferences/face.plist") else {
                fatalError("Must add \"SIMChat.bundle\" file")
            }
            guard let dic = NSDictionary(contentsOfURL: url) else {
                fatalError("file \"SIMChat.bundle/Preferences/face.plist\" load fail!")
            }
            // 生成列表
            let emojis = dic
                .sort { ($0.value as? Int) > ($1.value as? Int) }
                .map { Int($0.key as! String)! }
            
            // 生成page
            var pages = [Classic]()
            let maxEle = (3 * 7) - 1
            for i in 0 ..< (emojis.count + maxEle - 1) / maxEle {
                let beg = i * maxEle
                let end = min((i + 1) * maxEle, emojis.count)
                let page = Classic(emojis[beg ..< end].map({ String(format: "qq:%03d", $0) }))
                pages.append(page)
            }
            return pages
        }
        
        static func emojis() -> [Classic] {
            // 生成emoij函数
            let emoji = { (x:UInt32) -> String in
                var idx = ((((0x808080F0 | (x & 0x3F000) >> 4) | (x & 0xFC0) << 10) | (x & 0x1C0000) << 18) | (x & 0x3F) << 24)
                return withUnsafePointer(&idx) {
                    return NSString(bytes: $0, length: sizeof(idx.dynamicType), encoding: NSUTF8StringEncoding) as! String
                }
            }
            var emojis = [String]()
            for i:UInt32 in 0x1F600 ..< 0x1F64F {
                if i < 0x1F641 || i > 0x1F644 {
                    emojis.append(emoji(i))
                }
            }
            for i:UInt32 in 0x1F680 ..< 0x1F6A4 {
                emojis.append(emoji(i))
            }
            for i:UInt32 in 0x1F6A5 ..< 0x1F6C5 {
                emojis.append(emoji(i))
            }
            
            var pages = [Classic]()
            let maxEle = (3 * 7) - 1
            for i in 0 ..< (emojis.count + maxEle - 1) / maxEle {
                let beg = i * maxEle
                let end = min((i + 1) * maxEle, emojis.count)
                let page = Classic(Array(emojis[beg ..< end]))
                pages.append(page)
            }
            return pages
        }
    }
}

// MARK: - Private Method

extension SIMChatInputPanel.Face {
    private func build() {
        
        // add view
        addSubview(_contentView)
        addSubview(_pageControl)
        addSubview(_tabBar)
        addSubview(_preview)
        
        // add layout
        
        SIMChatLayout.make(_contentView)
            .top.equ(self).top
            .left.equ(self).left
            .right.equ(self).right
            .bottom.equ(_tabBar).top
            .submit()
        
        SIMChatLayout.make(_pageControl)
            .left.equ(self).left
            .right.equ(self).right
            .bottom.equ(_contentView).bottom(5)
            .submit()
        
        SIMChatLayout.make(_tabBar)
            .left.equ(self).left
            .right.equ(self).right
            .bottom.equ(self).bottom
            .submit()
        
        
        _pageControl.currentPage = 0
        _pageControl.numberOfPages = _pages.count
        //dispatch_async(dispatch_get_main_queue()) {
        //    self._contentView.reloadData()
        //    dispatch_async(dispatch_get_main_queue()) {
        //        self._contentView.scrollToItemAtIndexPath(NSIndexPath(forItem: 8, inSection: 0), atScrollPosition: .None, animated: false)
        //    }
        //}
    }
}

// MARK: - SIMChatInputPanelDelegateFaceOfClassic

extension SIMChatInputPanel.Face: SIMChatInputPanelDelegateFaceOfClassic {
    /// 选择
    @objc private func classic(classic: UIView, shouldSelectItem item: String) -> Bool {
        return delegate?.inputPanel?(self, shouldSelectFace: item) ?? true
    }
    @objc private func classic(classic: UIView, didSelectItem item: String) {
        delegate?.inputPanel?(self, didSelectFace: item)
    }
    /// 删除
    @objc private func classicShouldSelectBackspace(classic: UIView) -> Bool {
        return delegate?.inputPanelShouldSelectBackspace?(self) ?? true
    }
}

// MARK: - UICollectionViewDelegate or UICollectionViewDataSource

extension SIMChatInputPanel.Face: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        _pageControl.currentPage = Int((scrollView.contentOffset.x + scrollView.frame.width / 2.0) / scrollView.frame.width)
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _pages.count
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let page = _pages[indexPath.item]
        var identifier = NSStringFromClass(page.dynamicType)
        if _contentView.cellClasses[identifier] == nil {
            identifier = "Unknow"
        }
        return collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath)
    }
    
    public func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = cell as? Page.Classic, page = _pages[indexPath.item] as? Model.Classic {
            // 经典类型
            cell.model = page
            cell.preview = _preview
            cell.delegate = self
        }
        cell.backgroundColor = collectionView.backgroundColor
    }
}

// MARK: - Internal Delegate

@objc private protocol SIMChatInputPanelDelegateFaceOfClassic: NSObjectProtocol {
    
    optional func classic(classic: UIView, shouldSelectItem item: String) -> Bool
    optional func classic(classic: UIView, didSelectItem item: String)
    
    optional func classicShouldSelectBackspace(classic: UIView) -> Bool
    optional func classicDidSelectBackspace(classic: UIView)
}
