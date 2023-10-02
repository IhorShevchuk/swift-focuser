//
//  File.swift
//  
//
//  Created by Augustinas Malinauskas on 01/09/2021.
//

import SwiftUI
import Introspect

class TextFieldObserver: NSObject, UITextFieldDelegate {
    var onReturnTap: () -> () = {}
    weak var forwardToDelegate: UITextFieldDelegate?
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturnTap()
        return forwardToDelegate?.textFieldShouldReturn?(textField) ?? true
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if forwardToDelegate?.responds(to: aSelector) == true {
            return true
        }
        return super.responds(to: aSelector)
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return forwardToDelegate
    }
}

class TextViewObserver: NSObject, UITextViewDelegate {
    var onReturnTap: () -> () = {}
    weak var forwardToDelegate: UITextViewDelegate?

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text as NSString).rangeOfCharacter(from: CharacterSet.newlines).location != NSNotFound {
            textView.resignFirstResponder()
            onReturnTap()
        }
        return forwardToDelegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text) ?? true
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if forwardToDelegate?.responds(to: aSelector) == true {
            return true
        }
        return super.responds(to: aSelector)
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return forwardToDelegate
    }
}

public struct FocusModifier<Value: FocusStateCompliant & Hashable>: ViewModifier {
    @Binding var focusedField: Value?
    var equals: Value
    @State var textFieldObserver = TextFieldObserver()
    @State var textViewObserver = TextViewObserver()

    public func body(content: Content) -> some View {
        content
            .introspectTextField { tf in
                if !(tf.delegate is TextFieldObserver) {
                    textFieldObserver.forwardToDelegate = tf.delegate
                    tf.delegate = textFieldObserver
                }
                
                /// when user taps return we navigate to next responder
                textFieldObserver.onReturnTap = {
                    focusedField = focusedField?.next ?? Value.last
                }

                /// to show kayboard with `next` or `return`
                if equals.hashValue == Value.last.hashValue {
                    tf.returnKeyType = .done
                } else {
                    tf.returnKeyType = .next
                }
                
                if focusedField == equals {
                    tf.becomeFirstResponder()
                }
            }
            .introspectTextView(customize: {tv in
                if !(tv.delegate is TextViewObserver) {
                    textViewObserver.forwardToDelegate = tv.delegate
                    tv.delegate = textViewObserver
                }

                /// when user taps return we navigate to next responder
                textViewObserver.onReturnTap = {
                    focusedField = focusedField?.next ?? Value.last
                }

                /// to show kayboard with `next` or `return`
                if equals.hashValue == Value.last.hashValue {
                    tv.returnKeyType = .done
                } else {
                    tv.returnKeyType = .next
                }

                if focusedField == equals {
                    tv.becomeFirstResponder()
                }
            })
            .simultaneousGesture(TapGesture().onEnded {
              focusedField = equals
            })
    }
}
