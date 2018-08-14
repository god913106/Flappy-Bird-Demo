//
//  GameScene.swift
//  Flappy Bird Demo
//
//  Created by 洋蔥胖 on 2018/8/3.
//  Copyright © 2018年 ChrisYoung. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene , SKPhysicsContactDelegate{
    
    var bird = SKSpriteNode()
    var bg = SKSpriteNode()
    var timer = Timer()
    
    var scoreLabel = SKLabelNode()
    var score = 0
    var gameOverLabel = SKLabelNode()
    
    var gameOver = false
    
    enum ColliderType: UInt32 {
        
        case Bird = 1
        case Object = 2
        case Gap = 4
        
    }
    
    @objc func makePipes() {
        // 管子邏輯
        let movePipes = SKAction.move(by: CGVector(dx: -2 * self.frame.width, dy: 0), duration: TimeInterval(self.frame.width / 100))
        let removePipes = SKAction.removeFromParent()
        let moveAndRemovePipes = SKAction.sequence([movePipes, removePipes])
        
        let gapHeight = bird.size.height * 6 //鳥可通過的通道
        
        let movementAmount = arc4random() % UInt32(self.frame.height / 2)
        //這段要重看
        let pipeOffset = CGFloat(movementAmount) - self.frame.height / 4
        
        //上管
        let pipeTexture = SKTexture(imageNamed: "pipe1.png")
        
        let pipe1 = SKSpriteNode(texture: pipeTexture)
        //X軸都固定，Y軸 從0點開始往上扣掉(往上扣 就是增加y軸 大於0) 下管高度/2 鳥通道高度/2 + 隨機高度
        pipe1.position = CGPoint(x: self.frame.midX + self.frame.width, y: self.frame.midY + pipeTexture.size().height / 2 + gapHeight / 2 + pipeOffset)
        
        pipe1.run(moveAndRemovePipes)
        
        pipe1.physicsBody = SKPhysicsBody(rectangleOf: pipeTexture.size()) //初始化pipe1的size
        pipe1.physicsBody!.isDynamic = false //一個布爾值，指示物理模擬是否移動了物理主體。
        
        pipe1.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue //定义了哪种物体接触到该物体，该物体会收到通知（谁撞我我会收到通知）
        pipe1.physicsBody!.categoryBitMask = ColliderType.Object.rawValue //定义了这个物体所属分类
        pipe1.physicsBody!.collisionBitMask = ColliderType.Object.rawValue //定义了哪种物体会碰撞到自己
        
        pipe1.zPosition = -1 //因為會擋到分數跟重新開始的提示字串 所以z軸要-1
        
        self.addChild(pipe1)
        
        //下管
        let pipe2Texture = SKTexture(imageNamed: "pipe2.png")
        
        let pipe2 = SKSpriteNode(texture: pipe2Texture)
        //X軸都固定，Y軸 從0點開始往下扣掉(往下扣就是扣去y軸 小於0) 下管高度/2 鳥通道高度/2 + 隨機高度
        pipe2.position = CGPoint(x: self.frame.midX + self.frame.width, y: self.frame.midY - pipe2Texture.size().height / 2 - gapHeight / 2 + pipeOffset)
        
        pipe2.run(moveAndRemovePipes)
        
        pipe2.physicsBody = SKPhysicsBody(rectangleOf: pipeTexture.size()) //初始化pipe1的size
        pipe2.physicsBody!.isDynamic = false //一個布爾值，指示物理模擬是否移動了物理主體。
        
        pipe2.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue //定义了哪种物体接触到该物体，该物体会收到通知（谁撞我我会收到通知）
        pipe2.physicsBody!.categoryBitMask = ColliderType.Object.rawValue //定义了这个物体所属分类
        pipe2.physicsBody!.collisionBitMask = ColliderType.Object.rawValue //定义了哪种物体会碰撞到自己
        
        pipe2.zPosition = -1 //因為會擋到分數跟重新開始的提示字串 所以z軸要-1
        
        self.addChild(pipe2)
        
        //鳥通道
        let gap = SKNode() //鳥通道是一段節點所以沒有圖 不用SKTexture
        gap.position = CGPoint(x: self.frame.midX + self.frame.width, y: self.frame.midY + pipeOffset)
        
        gap.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: pipeTexture.size().width, height: gapHeight))
        
        gap.physicsBody!.isDynamic = false
        
        gap.run(moveAndRemovePipes)
        
        gap.physicsBody!.contactTestBitMask = ColliderType.Bird.rawValue //鳥撞到通道會通知
        gap.physicsBody!.categoryBitMask = ColliderType.Gap.rawValue    //定義這個物質為gap
        gap.physicsBody!.collisionBitMask = ColliderType.Gap.rawValue   //定义了哪种物体会碰撞到自己 自己對自己 = 0?
        
        self.addChild(gap)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if gameOver == false {
            
            //bodyA 物件左側 第一個碰撞點 bodyB 物件右側 第二個碰撞點 經過鳥通道這兩點 就分數+1
            if contact.bodyA.categoryBitMask == ColliderType.Gap.rawValue || contact.bodyB.categoryBitMask == ColliderType.Gap.rawValue {
                
                score += 1
                
                scoreLabel.text = String(score)
                
                
            } else {
                self.speed = 0
                
                gameOver = true
                
                timer.invalidate()
                
                gameOverLabel.fontName = "Helvetica"
                
                gameOverLabel.fontSize = 30
                
                gameOverLabel.text = "遊戲結束 請點擊營幕重新開始"
                
                gameOverLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
                
                self.addChild(gameOverLabel)
            }
        }
    }
    
    override func didMove(to view: SKView) {
        
        self.physicsWorld.contactDelegate = self
        
        setupGame()
    }
    
    // 設定/初始/重置 遊戲
    func setupGame() {
        
        //管子3秒一次的Timer
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.makePipes), userInfo: nil, repeats: true)
        
        //記得一個大原則：圖是疊加上去的，所以要疊在最後面的背景要先寫，會飛的鳥兒要最後再寫
        //new一個背景
        let bgTexture = SKTexture(imageNamed: "bg.png")
        //幫背景加上動畫
        let moveBGAnimation = SKAction.move(by: CGVector(dx: -bgTexture.size().width, dy: 0), duration: 7)
        let shiftBGAnimation = SKAction.move(by: CGVector(dx: bgTexture.size().width, dy: 0), duration: 0)
        let moveBGForever = SKAction.repeatForever(SKAction.sequence([moveBGAnimation, shiftBGAnimation]))
        
        //同一個背景bg add了三個 保持動畫一定可以永遠run下去
        var i: CGFloat = 0
        
        while i < 3 {
            bg = SKSpriteNode(texture: bgTexture)
            bg.position = CGPoint(x: bgTexture.size().width * i, y: self.frame.midY)
            bg.size.height = self.frame.height //部滿營幕的高
            bg.run(moveBGForever)
            bg.zPosition = -2 //Z軸 置於背後
            self.addChild(bg)
            i += 1
            
        }
        
        //new兩個鳥物件
        let birdTexture = SKTexture(imageNamed: "flappy1.png")
        let birdTexture2 = SKTexture(imageNamed: "flappy2.png")
        //加入動畫 這兩個圖連動 間隔0.1秒 重播永遠
        let animation = SKAction.animate(with: [birdTexture, birdTexture2], timePerFrame: 0.1)
        let makeBirdFlap = SKAction.repeatForever(animation)
        
        bird = SKSpriteNode(texture: birdTexture)
        
        //把鳥的位子固定在中間
        bird.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        
        bird.run(makeBirdFlap)
        
        //幫鳥兒加上物理事件
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: birdTexture.size().height / 2)
        
        bird.physicsBody!.isDynamic = false
        
        bird.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue //跟上下管碰撞時 給通知
        bird.physicsBody!.categoryBitMask = ColliderType.Bird.rawValue  //分類 = 鳥
        bird.physicsBody!.collisionBitMask = ColliderType.Bird.rawValue //又是鳥自己對自己
        
        self.addChild(bird)
        
        //new一個分數物件
        scoreLabel.fontName = "Helvetica"
        
        scoreLabel.fontSize = 60
        
        scoreLabel.text = "0"
        
        scoreLabel.position = CGPoint(x: self.frame.midX, y: self.frame.height / 2 - 70)
        
        self.addChild(scoreLabel)
        
    }
    
    //觸碰營幕後的事件
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if gameOver == false {
            
            bird.physicsBody!.isDynamic = true
            
            bird.physicsBody!.velocity = CGVector(dx: 0, dy: 0) //物理體的速度矢量，以米/秒為單位。
            
            bird.physicsBody!.applyImpulse(CGVector(dx: 0, dy: 60)) //對物理體的重心施加衝動。
            
        }else {
            
            gameOver = false
            score = 0
            
            self.speed = 1
            self.removeAllChildren()
            
            setupGame()
            
        }
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
