//
//  EventType.swift
//  EmojiApps
//
//  Created by Alexandru Culeva on 1/23/17.
//  Copyright © 2017 Yopeso. All rights reserved.
//

enum EventType {
    
    case obevent(OBEvent)
    
    var key: String {
        switch self {
        case let .obevent(obevent):                             return obevent.firebaseKey
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case let .obevent(obevent): return obevent.parameters
        }
    }
    
    
    enum OBEvent {
        case general(Onboarding)
        case firstStart(Onboarding)
        
        var firebaseKey: String {
            switch self {
                case .general(let onboarding):                      return "ONBOARDING_" + onboarding.firebaseKey
                case .firstStart(let onboarding):                   return "FIRST_OPEN_INTRO_" + onboarding.firebaseKey
            }
        }
        
        var parameters: [String: Any]? {
            switch self {
                case .general(let onboarding):                      return onboarding.parameters
                case .firstStart(let onboarding):                   return onboarding.parameters
            }
        }
    }
    
    enum Onboarding {
        case screenShown(OnboardingScreen)
        case rewardCollected
        case backSelected(OnboardingScreen)
        case flowDismissed(OnboardingScreen)
        case screenSkipped(OnboardingScreen)
        case ctaSelected(OnboardingScreen)
        case installConfirmed(Extension)
        case videoInstructionsDismissed(Extension)
        case start
        case complete
        
        var firebaseKey: String {
            switch self {
                case .screenShown(_):                       return "screen_shown"
                case .rewardCollected:                      return "reward_collected"
                case .backSelected(_):                      return "back_selected"
                case .flowDismissed(_):                     return "flow_dismissed"
                case .screenSkipped(_):                     return "screen_skipped"
                case .ctaSelected(_):                       return "cta_selected"
                case .installConfirmed(_):                  return "install_confirmed"
                case .videoInstructionsDismissed(_):        return "video_instructions_dismissed"
                case .start:                                return "start"
                case .complete:                             return "complete"
            }
        }
        
        var parameters: [String: Any]? {
            switch self {
            case let .screenShown(screen): return [kParameterScreen : screen.rawValue]
            case let .backSelected(screen): return [kParameterScreen : screen.rawValue]
            case let .flowDismissed(screen): return [kParameterScreen : screen.rawValue]
            case let .screenSkipped(screen): return [kParameterScreen : screen.rawValue]
            case let .ctaSelected(screen): return [kParameterScreen : screen.rawValue]
            case let .installConfirmed(ext): return [kParameterExtension : ext.rawValue]
            case let .videoInstructionsDismissed(ext): return [kParameterExtension : ext.rawValue]
            default: return nil
            }
        }
    }
    
    enum OnboardingScreen: String {
        case gameReward         = "Game Reward"
        case iMessageInstall    = "iMessage Install"
        case keyboardInstall    = "Keyboard Install"
        case emojiRequest       = "Emoji Request"
        case emojiGames         = "Emoji Games"
    }
    
    enum Extension: String {
        case iMessage
        case Keyboard
    }
}

extension EventType: Equatable { }
func == (lhs: EventType, rhs: EventType) -> Bool {
    return lhs.key == rhs.key
}

extension EventType: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}

extension EventType {
    static let kParameterScreen = "screen"
    static let kParameterExtension = "extension"
}

//
//  FirebaseEventTracker.swift
//  EmojiApps
//
//  Created by Alexandru Culeva on 1/23/17.
//  Copyright © 2017 Yopeso. All rights reserved.
//

import Foundation
import FirebaseAnalytics

struct Event {
    let type: EventType
    let parameters: [String: Any]?
    
    init(event: EventType) {
        self.type = event
        self.parameters = event.parameters
    }
    
    init(type: EventType, parameters: [EventType: Any]? = nil) {
        self.type = type
        let mappedDictionary = parameters?.map { (event, value) in (event.key, value) }
        self.parameters = mappedDictionary.flatMap { Dictionary(uniqueKeysWithValues: $0) } ?? [:]
    }
    
    init(type: EventType, parameters: [String: Any]? = nil) {
        self.type = type
        self.parameters = parameters
    }
}

struct FirebaseEventTracker {
    
    static func track(_ type: EventType, parameters: [String: Any]? = nil) {
        var finalParameters: [String: Any]? = nil
        parameters.apply { finalParameters = $0 }
        type.parameters.apply { finalParameters = (finalParameters ?? [:]) + $0 }
        
        track(Event(type: type, parameters: finalParameters))
    }
    
    static func track(_ event: Event) {
        Analytics.logEvent(event.type.key, parameters: event.parameters as? [String: NSObject] ?? [:])
    }
    
    static func trackEventStart(_ type: EventType) {
        // seems to be no support for that, just track as a regular event
        track(Event(type: type, parameters: type.parameters))
    }
    
    static func trackEventEnd(_ type: EventType) {
        // do nothing, seems to be no support for that
    }
}

extension Optional {
    func apply<T>(_ function: (Wrapped) -> T?) -> T? {
        guard case let .some(p) = self else { return nil }
        return function(p)
    }
}

/// Add two dictionaries by updating the keys in first with values from second.
func +<K, V>(lhs: [K: V], rhs: [K: V]) -> [K: V] {
    var mutable = lhs
    for (key, value) in rhs {
        mutable[key] = value
    }
    return mutable
}
