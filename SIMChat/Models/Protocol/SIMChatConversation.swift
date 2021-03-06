//
//  SIMChatConversation.swift
//  SIMChat
//
//  Created by sagesse on 10/15/15.
//  Copyright © 2015 Sagesse. All rights reserved.
//

import Foundation

/// 消息处理者
public typealias SIMChatMessageHandler = SIMChatResult<SIMChatMessage, NSError> -> Void
public typealias SIMChatMessagesHandler = SIMChatResult<Array<SIMChatMessage>, NSError> -> Void

///
/// 抽象的聊天会话协议.
///
public protocol SIMChatConversation: class {
    
    // MARK: User Info
    
    ///
    /// 会话类型, 默认值由receiver指定
    ///
    var type: SIMChatConversationType { get }
    ///
    /// 接收者信息
    ///
    var receiver: SIMChatUserProtocol { get }
    ///
    /// 发送都信息
    ///
    var sender: SIMChatUserProtocol { get }
    
    // MARK: Util
    
    ///
    /// 最新的一条消息, 如果为nil则没有
    ///
    var latest: SIMChatMessage? { get }
    ///
    /// 未读消息数量, 为0则没有
    ///
    var unreadCount: Int { get }
    ///
    /// 所有消息都己经加载
    ///
    var allMessagesIsLoaded: Bool { get }
    
    ///
    /// 管理器
    ///
    weak var manager: SIMChatManager? { get }
    ///
    /// 远程消息代理
    ///
    weak var delegate: SIMChatConversationDelegate? { set get }
    
    // MARK: Message Methos
    
    ///
    /// 发送一条消息(重新发送)
    ///
    /// - parameter message: 需要发送的消息
    /// - parameter closure: 执行结果
    ///
    func sendMessage(message: SIMChatMessage, closure: SIMChatMessageHandler?)
    ///
    /// 发送一条消息(新建)
    ///
    /// - parameter content: 消息内容
    /// - returns: 新建的消息
    ///
    func sendMessage(content: SIMChatMessageBody, closure: SIMChatMessageHandler?) -> SIMChatMessage
    ///
    /// 更新消息状态
    ///
    /// - parameter message: 需要发送的消息
    /// - parameter status:  新的状态, 一般检查该状态来决定是否需要访问网络
    /// - parameter closure: 执行结果
    ///
    func updateMessage(message: SIMChatMessage, status: SIMChatMessageStatus, closure: SIMChatMessageHandler?)
    ///
    /// 加载(历史)消息
    ///
    /// - parameter last: 最后一条消息, 如果为nil则没有
    /// - parameter count: 容量
    /// - parameter closure: 执行结果
    ///
    func loadHistoryMessages(last: SIMChatMessage?, count: Int, closure: SIMChatMessagesHandler?)
    
    
    ///
    /// 删除消息
    ///
    /// - parameter message: 需要删除的消息
    /// - parameter closure: 执行结果
    ///
    func removeMessage(message: SIMChatMessage, closure: SIMChatMessageHandler?)
    
    // MARK: Message Of Remote
    
    ///
    /// 服务端要求更新消息(被动)
    ///
    /// - parameter message: 被操作的消息
    ///
    func updateMessageFromRemote(message: SIMChatMessage)
    ///
    /// 接收到来自服务端的消息(被动)
    ///
    /// - parameter message: 被操作的消息
    ///
    func receiveMessageFromRemote(message: SIMChatMessage)
    ///
    /// 服务端要求更删除消息(被动)
    ///
    /// - parameter message: 被操作的消息
    ///
    func removeMessageFromRemote(message: SIMChatMessage)
    
    // MARK: Generate
    
    ///
    /// 创建一个新的会话
    ///
    /// - parameter receiver: 会话的接收者
    ///
    static func conversation(receiver: SIMChatUserProtocol, manager: SIMChatManager) -> SIMChatConversation
}

// MARK: - Convenience

extension SIMChatConversation {
    ///
    /// 会话类型, 默认值由receiver指定
    ///
    public var type: SIMChatConversationType {
        switch receiver.type {
        case .User:     return .C2C
        case .System:   return .C2C
        case .Group:    return .Group
        }
    }
    ///
    /// 加载(历史)消息
    ///
    /// - parameter last: 最后一条消息, 如果为nil则没有
    /// - parameter count: 容量
    /// - parameter closure: 执行结果
    ///
    public func loadHistoryMessages(count: Int, closure: SIMChatMessagesHandler?) {
        loadHistoryMessages(nil, count: count, closure: closure)
    }
}

/// 代理
public protocol SIMChatConversationDelegate: class {
    ///
    /// 新消息通知
    ///
    /// - parameter conversation: 发生事件的会话
    /// - parameter message: 接收到的消息
    ///
    func conversation(conversation: SIMChatConversation, didReciveMessage message: SIMChatMessage)
    ///
    /// 删除消息通知
    ///
    /// - parameter conversation: 发生事件的会话
    /// - parameter message: 接收到的消息
    ///
    func conversation(conversation: SIMChatConversation, didRemoveMessage message: SIMChatMessage)
    ///
    /// 更新消息通知
    ///
    /// - parameter conversation: 发生事件的会话
    /// - parameter message: 接收到的消息
    ///
    func conversation(conversation: SIMChatConversation, didUpdateMessage message: SIMChatMessage)
}

///
/// 会话类型
///
public enum SIMChatConversationType: Int {
    case C2C
    case Group
}

// MARK: - User compare

public func !=(lhs: SIMChatConversation, rhs: SIMChatConversation?) -> Bool {
    return !(lhs == rhs)
}
public func ==(lhs: SIMChatConversation, rhs: SIMChatConversation?) -> Bool {
    return lhs.receiver == rhs?.receiver
}
