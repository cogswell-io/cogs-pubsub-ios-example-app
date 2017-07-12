
import Foundation
import CogsSDK

class WSSMessagingVC: ViewController {

    @IBOutlet weak var readKeyTextField: UITextField!
    @IBOutlet weak var writeKeyTextField: UITextField!
    @IBOutlet weak var adminKeyTextField: UITextField!

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var sessionUUIDLabel: UILabel!
    @IBOutlet weak var channelNameTextField: UITextField!
    @IBOutlet weak var channelListLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var messageChannelTextField: UITextField!
    @IBOutlet weak var ackSwitch: UISwitch!
    @IBOutlet weak var receivedMessageLabel: UILabel!
    @IBOutlet weak var acknowledgeLabel: UILabel!

    private var connectionHandle: PubSubConnectionHandle!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func connectWS(_ sender: UIBarButtonItem) {
        
        guard let readKey  = readKeyTextField.text else { return }
        guard let writeKey = writeKeyTextField.text else { return }
        guard let adminKey = adminKeyTextField.text else { return }
        
        let keys: [String] = [readKey, writeKey, adminKey]

        let defaultOptions    = PubSubOptions.defaultOptions
        let connectionHandle  = PubSubService.connect(keys: keys, options: defaultOptions)
        self.connectionHandle = connectionHandle
        
        connectionHandle.onNewSession = { sessionUUID in
            DispatchQueue.main.async {
                self.statusLabel.text = "New session is opened"
                self.sessionUUIDLabel.text = sessionUUID
            }
        }

        connectionHandle.onReconnect = {
            DispatchQueue.main.async {
                self.statusLabel.text = "Session is restored"
            }
        }

        connectionHandle.onClose = { (error) in
            if let err = error {
                self.openAlertWithMessage(message: err.localizedDescription, title: "PubSub Error")
            } else {
                DispatchQueue.main.async {
                    self.statusLabel.text = "Session is closed"
                }
            }
        }

        connectionHandle.onMessage = { (receivedMessage) in
            DispatchQueue.main.async {
                self.receivedMessageLabel.text = receivedMessage.message
            }
        }

        connectionHandle.onError = { (error) in
            self.openAlertWithMessage(message: error.localizedDescription, title: "PubSub Error")
        }

        connectionHandle.onErrorResponse = { (responseError) in
              self.openAlertWithMessage(message: responseError.message, title: "PubSub Response Error")
        }
    }

    @IBAction func disconnectWS(_ sender: UIBarButtonItem) {
        guard (connectionHandle) != nil else { return }

        connectionHandle.close()
    }

    @IBAction func getSessionUUID(_ sender: UIButton) {
        guard (connectionHandle) != nil else { return }

        connectionHandle.getSessionUuid() { outcome in
            switch outcome {
            case .pubSubSuccess(let object):
                if let uuid = object as? String {
                    DispatchQueue.main.async {
                        self.sessionUUIDLabel.text = uuid
                    }
                }
            case .pubSubResponseError(let error):
                self.openAlertWithMessage(message: error.message, title: "PubSub Response Error")
            }
        }
    }

    @IBAction func subscribeToChannel(_ sender: UIButton) {
        guard let channelName = channelNameTextField.text, !channelName.isEmpty else { return }
        guard (connectionHandle) != nil else { return }

        connectionHandle.subscribe(channel: channelName, messageHandler: nil) { outcome in
            switch outcome {
            case .pubSubSuccess(let object):
                if let channels = object as? [String] {
                    DispatchQueue.main.async {
                        self.channelListLabel.text = "\(channels)"
                    }
                }
            case .pubSubResponseError(let error):
                self.openAlertWithMessage(message: error.message, title: "PubSub Response Error")
            }
        }
    }

    @IBAction func unsubscribeFromCahnnel(_ sender: UIButton) {
        guard let channelName = channelNameTextField.text, !channelName.isEmpty else { return }
        guard (connectionHandle) != nil else { return }

        connectionHandle.unsubscribe(channel: channelName) { outcome in
            switch outcome {
            case .pubSubSuccess(let object):
                if let channels = object as? [String] {
                    DispatchQueue.main.async {
                        self.channelListLabel.text = "\(channels)"
                    }
                }
            case .pubSubResponseError(let error):
                self.openAlertWithMessage(message: error.message, title: "PubSub Response Error")
            }
        }
    }

    @IBAction func getAllSubscriptions(_ sender: UIButton) {
        guard (connectionHandle) != nil else { return }

        connectionHandle.listSubscriptions() { outcome in

            switch outcome {
            case .pubSubSuccess(let object):
                if let channels = object as? [String] {
                    DispatchQueue.main.async {
                        self.channelListLabel.text = "\(channels)"
                    }
                }
            case .pubSubResponseError(let error):
                self.openAlertWithMessage(message: error.message, title: "PubSub Response Error")
            }
        }
    }

    @IBAction func unsubscribeFromAll(_ sender: UIButton) {
        guard (connectionHandle) != nil else { return }

        connectionHandle.unsubscribeAll() { outcome in
            switch outcome {
            case.pubSubSuccess(let object):
                if let channels = object as? [String] {
                    DispatchQueue.main.async {
                        self.channelListLabel.text = "\(channels)"
                    }
                }
            case .pubSubResponseError(let error):
                self.openAlertWithMessage(message: error.message, title: "PubSub Response Error")
            }
        }
    }

    @IBAction func publishMessage(_ sender: UIButton) {
        guard let channel = channelNameTextField.text, !channel.isEmpty else { return }
        let messageText = messageTextView.text!
        let ack = ackSwitch.isOn

        guard (connectionHandle) != nil else { return }

        if ack {
            connectionHandle.publishWithAck(channel: channel, message: messageText) { outcome in
                switch outcome {
                case .pubSubSuccess(let object):
                    if let messageUuid = object as? String {
                        DispatchQueue.main.async {
                            self.acknowledgeLabel.text = messageUuid
                        }
                    }
                case .pubSubResponseError(let error):
                    DispatchQueue.main.async {
                        self.acknowledgeLabel.text = error.message
                    }
                }
            }
        } else {
            connectionHandle.publish(channel: channel, message: messageText) { error in
                guard (error) != nil else { return }
                self.openAlertWithMessage(message: error!.message, title: "PubSub Response Error")
            }
        }
    }

    fileprivate func openAlertWithMessage(message msg: String, title: String) {
        let actionCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        actionCtrl.addAction(action)

        DispatchQueue.main.async {
            self.present(actionCtrl, animated: true, completion: nil)
        }
    }
}
