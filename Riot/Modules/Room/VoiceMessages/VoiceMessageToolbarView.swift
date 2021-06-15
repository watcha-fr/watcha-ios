// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit

protocol VoiceMessageToolbarViewDelegate: AnyObject {
    func voiceMessageToolbarViewDidRequestRecordingStart(_ toolbarView: VoiceMessageToolbarView)
    func voiceMessageToolbarViewDidRequestRecordingCancel(_ toolbarView: VoiceMessageToolbarView)
    func voiceMessageToolbarViewDidRequestRecordingFinish(_ toolbarView: VoiceMessageToolbarView)
}

enum VoiceMessageToolbarViewUIState {
    case idle
    case recording
}

class VoiceMessageToolbarView: PassthroughView, Themable, UIGestureRecognizerDelegate {
    @IBOutlet private var backgroundView: UIView!
    
    @IBOutlet private var recordButtonsContainerView: UIView!
    @IBOutlet private var primaryRecordButton: UIButton!
    @IBOutlet private var secondaryRecordButton: UIButton!
    
    @IBOutlet private var recordingChromeContainerView: UIView!
    @IBOutlet private var recordingIndicatorView: UIView!
    
    @IBOutlet private var slideToCancelContainerView: UIView!
    @IBOutlet private var slideToCancelLabel: UILabel!
    @IBOutlet private var slideToCancelChevron: UIImageView!
    @IBOutlet private var slideToCancelGradient: UIImageView!
    
    @IBOutlet private var elapsedTimeLabel: UILabel!
    
    private var cancelLabelToRecordButtonDistance: CGFloat = 0.0
    
    private var currentTheme: Theme? {
        didSet {
            updateUIAnimated(true)
        }
    }
    
    weak var delegate: VoiceMessageToolbarViewDelegate?
    
    var state: VoiceMessageToolbarViewUIState = .idle {
        didSet {
            switch state {
            case .recording:
                let convertedFrame = self.convert(slideToCancelLabel.frame, from: slideToCancelContainerView)
                cancelLabelToRecordButtonDistance = recordButtonsContainerView.frame.minX - convertedFrame.maxX
                startAnimatingRecordingIndicator()
            case .idle:
                cancelDrag()
            }
            
            updateUIAnimated(true)
        }
    }
    
    var elapsedTime: String? {
        didSet {
            elapsedTimeLabel.text = elapsedTime
        }
    }
        
    @objc static func instanceFromNib() -> VoiceMessageToolbarView {
        let nib = UINib(nibName: "VoiceMessageToolbarView", bundle: nil)
        guard let view = nib.instantiate(withOwner: nil, options: nil).first as? Self else {
          fatalError("The nib \(nib) expected its root view to be of type \(self)")
        }
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        slideToCancelGradient.image = Asset.Images.voiceMessageCancelGradient.image.withRenderingMode(.alwaysTemplate)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.delegate = self
        longPressGesture.minimumPressDuration = 0.1
        recordButtonsContainerView.addGestureRecognizer(longPressGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        longPressGesture.delegate = self
        recordButtonsContainerView.addGestureRecognizer(panGesture)
        
        updateUIAnimated(false)
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        currentTheme = theme
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: - Private
    
    @objc private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case UIGestureRecognizer.State.began:
            delegate?.voiceMessageToolbarViewDidRequestRecordingStart(self)
        case UIGestureRecognizer.State.ended:
            delegate?.voiceMessageToolbarViewDidRequestRecordingFinish(self)
        case UIGestureRecognizer.State.cancelled:
            delegate?.voiceMessageToolbarViewDidRequestRecordingCancel(self)
        default:
            break
        }
    }
    
    @objc private func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard self.state == .recording && gestureRecognizer.state == .changed else {
            return
        }
        
        let translation = gestureRecognizer.translation(in: self)
        
        secondaryRecordButton.transform = CGAffineTransform(translationX: min(translation.x, 0.0), y: 0.0)
        slideToCancelContainerView.transform = CGAffineTransform(translationX: min(translation.x + cancelLabelToRecordButtonDistance, 0.0), y: 0.0)
        
        if abs(translation.x - recordButtonsContainerView.frame.width / 2.0) > self.bounds.width / 2.0 {
            cancelDrag()
        }
    }
    
    private func cancelDrag() {
        recordButtonsContainerView.gestureRecognizers?.forEach { gestureRecognizer in
            gestureRecognizer.isEnabled = false
            gestureRecognizer.isEnabled = true
        }
    }
    
    private func updateUIAnimated(_ animated: Bool) {
        UIView.animate(withDuration: (animated ? 0.25 : 0.0)) {
            switch self.state {
            case .idle:
                self.backgroundView.alpha = 0.0
                self.primaryRecordButton.alpha = 1.0
                self.secondaryRecordButton.alpha = 0.0
                self.recordingChromeContainerView.alpha = 0.0
            case .recording:
                self.backgroundView.alpha = 1.0
                self.primaryRecordButton.alpha = 0.0
                self.secondaryRecordButton.alpha = 1.0
                self.recordingChromeContainerView.alpha = 1.0
            }
            
            guard let theme = self.currentTheme else {
                return
            }
            
            self.backgroundView.backgroundColor = theme.backgroundColor
            self.slideToCancelGradient.tintColor = theme.backgroundColor
            
            self.primaryRecordButton.tintColor = theme.textTertiaryColor
            self.slideToCancelLabel.textColor = theme.textSecondaryColor
            self.slideToCancelChevron.tintColor = theme.textSecondaryColor
            self.elapsedTimeLabel.textColor = theme.textSecondaryColor
        } completion: { _ in
            switch self.state {
            case .idle:
                self.secondaryRecordButton.transform = .identity
                self.slideToCancelContainerView.transform = .identity
            default:
                break
            }
        }
    }
    
    private func startAnimatingRecordingIndicator() {
        if self.state != .recording {
            return
        }
        
        UIView.animate(withDuration: 0.5) {
            if self.recordingIndicatorView.alpha > 0.0 {
                self.recordingIndicatorView.alpha = 0.0
            } else {
                self.recordingIndicatorView.alpha = 1.0
            }
        } completion: { [weak self] _ in
            self?.startAnimatingRecordingIndicator()
        }
        
    }
}
