//
//  GameScene.swift
//  Pencilita
//
//  Created by Rike-Benjamin Schuppner on 12.08.19.
//  Copyright © 2019 Rike-Benjamin Schuppner. All rights reserved.
//

import SpriteKit
import GameplayKit


import SwiftyZeroMQ

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    private var zmqContext : SwiftyZeroMQ.Context?
    private var zmqSocket : SwiftyZeroMQ.Socket?
    private var zmqPoller : SwiftyZeroMQ.Poller?
    
    private var bot: Bot?
    
    
    override func didMove(to view: SKView) {
        
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        do {
            // Define a TCP endpoint along with the text that we are going to send/recv
            let endpoint     = "tcp://0.0.0.0:5555"
            
            if let sock = self.zmqSocket {
                if let socks = try self.zmqPoller?.poll(timeout: 10) {
                
                for subscriber in socks.keys {

                    if socks[subscriber] == SwiftyZeroMQ.PollFlags.pollIn {
                        
                        if let msg = try subscriber.recv(bufferLength: 60000, options: .dontWait) {
                            print(msg)
                            let jsonDecoder = JSONDecoder()
                            let bot = try jsonDecoder.decode(Bot.self, from: msg.data(using: .utf8)!)
                            print(bot)
                            self.bot = bot
                        }
                        
                    } else {
                        print("\(sock): Nothing")
                    }
                }
                print("---")
                    
                }
                

            } else {
                self.zmqContext = try SwiftyZeroMQ.Context()
                self.zmqSocket = try self.zmqContext?.socket(.pair)
                self.zmqPoller = SwiftyZeroMQ.Poller()
                if let sock = self.zmqSocket {
                    try self.zmqPoller?.register(socket: sock, flags: .pollIn)
                    try sock.bind(endpoint)
                }
            }
            
        } catch {
            print(error)
        }

        
        if let bot = self.bot {
            for point in bot.walls {
                let shapeNode = SKShapeNode(circleOfRadius: 1.0 * 4)
                shapeNode.fillColor = SKColor.blue
                shapeNode.position = CGPoint(x: point.x * 4, y: point.y * 4)
                self.addChild(shapeNode)
            }
        }
        
        
    }
}
