//
//  SocketEvent.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation

enum SocketEvent: String, CaseIterable {
    case connect = "connect"
    case disconnect = "disconnect"
    case error = "error"
    
    // Room Events
    case joinRoom = "join_room"
    case leaveRoom = "leave_room"
    case roomJoined = "room_joined"
    case roomLeft = "room_left"
    
    // Message Events
    case sendMessage = "send_message"
    case receiveMessage = "receive_message"
    case messageDelivered = "message_delivered"
    case messageRead = "message_read"
    
    // User Events
    case userJoined = "user_joined"
    case userLeft = "user_left"
    case userOnline = "user_online"
    case userOffline = "user_offline"
    
    // Typing Events
    case startTyping = "start_typing"
    case stopTyping = "stop_typing"
    case userTyping = "user_typing"
    case userStoppedTyping = "user_stopped_typing"
}

enum SocketConnectionStatus {
    case connecting
    case connected
    case disconnected
    case error(String)
}