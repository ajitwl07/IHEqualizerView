//  MIT License
//
//Copyright (c) 2017 Md Ibrahim Hassan
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

import UIKit
import AVFoundation

protocol IHWaveFormViewDelegate : class {
    func didFinishPlayBack()
    func didStartPlayingWithSuccess()
}

@objc protocol IHWaveFormViewDataSource : class {
    func urlToPlay() -> URL
    @objc optional func lineWidth() -> CGFloat
    @objc optional func lineSeperation() -> CGFloat
}

class IHWaveFormView: UIView, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer!
    private var dataArray : [Float] = []
    private var totalCount : Int = 0
    private var xPoint : CGFloat = 0.0
    private var gameTimer: Timer!
    private var internalLineWidth : CGFloat!
    private var internalLineSeperation : CGFloat!
    weak var delegate : IHWaveFormViewDelegate?
    weak var dataSource : IHWaveFormViewDataSource?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xPoint = 0.0
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xPoint = 0.0
    }
    
    fileprivate var width : CGFloat?
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.commonInit()
        self.getPath(url: urlToPlay!)
    }
    
    var orientationChangesCount : Int = 0
    func rotated(sender: UIDeviceOrientation) {
        orientationChangesCount += 1
            if (orientationChangesCount == 1) {
                return
            }
        redrawView()
    }
    
   func eraseView() {
        for views in subviews {
            views.removeFromSuperview()
        }
        self.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }
    
    internal func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.gameTimer.invalidate()
        delegate?.didFinishPlayBack()
    }
    
    var centerLineView : UIView?
    
    func addCentreLine(){
        centerLineView = UIView.init(frame: CGRect.init(x: 0, y: self.frame.size.height / 2.0, width: self.frame.size.width, height: 1))
        centerLineView?.backgroundColor = .black
        self.addSubview(centerLineView!)
    }
    
    func invertColor(_ color : UIColor) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        self.backgroundColor?.getRed(&r, green: &g, blue: &b, alpha: &a)
        let lineColor = UIColor.init(red: self.invertB(r), green: self.invertB(g), blue: self.invert(b), alpha: a)
        return lineColor
    }
    
    func invertB(_ val : CGFloat) -> CGFloat{
        return (1.0 - val) * 0.9
    }
    
    func invert(_ val : CGFloat) -> CGFloat{
        if (val > 0.6 && val < 0.90){
            return 0.6 + 0.1
        }
        return (1.0 - val)
    }
    
    private var urlToPlay : URL?
    
    func setUpView(urlToPlay : URL, lineWith : CGFloat?, lineSeperation : CGFloat?) {
        if (lineWith != nil){
            internalLineWidth = lineWith
        }
        if (lineSeperation != nil){
            internalLineSeperation = lineSeperation
        }
        self.urlToPlay = urlToPlay
    }
    
    func commonInit(){
        internalLineWidth = 2.0
        internalLineSeperation = 1.0
        //        self.addOverlayLabels()
        self.addCentreLine()
    }
    
    private func getPath(url : URL){
        do {
            if player != nil,
                (player.isPlaying) {
                xPoint = 0
                    for i in dataArray {
                        if (xPoint < CGFloat(player.currentTime) / CGFloat(player.duration) * self.bounds.width) {
                            let twoDecimalPlaces = String(format: "%.2f", i)
                            self.generatePoints1(dBVal: twoDecimalPlaces)
                        }
                        else{
                            break
                        }
                    }
                
                let val : CGFloat = CGFloat(player.duration) / (CGFloat(self.frame.size.width - xPoint) * CGFloat(player.rate))
                self.trackAudio()
                gameTimer.invalidate()
                gameTimer = Timer.scheduledTimer(timeInterval: TimeInterval(val * (internalLineWidth + internalLineSeperation)), target: self, selector: #selector(trackAudio), userInfo: nil, repeats: true)
                return
            }
            player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.enableRate = true
            player.isMeteringEnabled = true
            player.play()
            delegate?.didStartPlayingWithSuccess()
            let duration = player.duration
            let val : CGFloat = CGFloat(duration) / (CGFloat(self.frame.size.width) * CGFloat(player.rate))
            self.trackAudio()
            gameTimer = Timer.scheduledTimer(timeInterval: TimeInterval(val * (internalLineWidth + internalLineSeperation)), target: self, selector: #selector(trackAudio), userInfo: nil, repeats: true)
        } catch {
            // couldn't load file :(
        }
    }
    
    private func makeNewWaveForm(_ yValNegative : CGFloat) -> (CGFloat){
        let totalHeight = self.frame.size.height / 12.0
        let yVal : CGFloat = CGFloat(abs(yValNegative))
        var yOffSet : CGFloat = totalHeight * 5 + (120 - 10)/(120 - 10) * totalHeight
        if (yVal > 0 && yVal <= 1){
            yOffSet = (yVal - 0)/(1) * totalHeight
        }
        else if (yVal > 1 && yVal <= 3){
            yOffSet = totalHeight + (yVal - 1)/2 * totalHeight
        }
        else if (yVal > 3 && yVal <= 6){
            yOffSet = totalHeight * 2 + (yVal - 3)/3 * totalHeight
        }
        else if (yVal > 6 && yVal <= 7){
            yOffSet = totalHeight * 3 + (yVal - 6)/1 * totalHeight
        }
        else if (yVal > 7 && yVal <= 10){
            yOffSet = totalHeight * 4 + (yVal - 7)/3 * totalHeight
        }
        else if (yVal > 10 && yVal <= 120){
            yOffSet = totalHeight * 5 + (yVal - 10)/(120 - 10) * totalHeight
        }
        return (yOffSet)
    }
    
    private func getReflectionPoint(yInput : CGFloat) -> CGFloat{
        return (self.frame.size.height - CGFloat(abs(yInput)))
    }
    
    @objc private func trackAudio() {
        NotificationCenter.default.addObserver(self, selector: #selector(rotated(sender:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        player.updateMeters()
        let dBLogValue : Float = player.averagePower(forChannel: 0)
        dataArray.append(dBLogValue)
        let twoDecimalPlaces = String(format: "%.2f", dataArray[totalCount])
        totalCount += 1
        self.generatePoints1(dBVal: twoDecimalPlaces)
    }
    
    private func redrawView() {
        eraseView()
        self.commonInit()
        self.getPath(url: urlToPlay!)
    }

    
    private func generatePoints1(dBVal : String){
        let aPath = UIBezierPath()
        let floatVal : Float = Float(dBVal)!
        let fromYPoint : CGFloat = self.makeNewWaveForm(CGFloat(floatVal))
        let toYPoint : CGFloat = self.getReflectionPoint(yInput: fromYPoint)
        aPath.move(to: CGPoint(x:xPoint , y: fromYPoint))
        aPath.addLine(to: CGPoint(x: xPoint, y: toYPoint))
        let diff = toYPoint - fromYPoint
        let shapeLayer1 = CAShapeLayer()
        let shapeLayer2 = CAShapeLayer()
        let shapeLayer3 = CAShapeLayer()
        self.layer.insertSublayer(shapeLayer1, at: 0)
        self.layer.insertSublayer(shapeLayer2, at: 1)
        self.layer.insertSublayer(shapeLayer3, at: 2)
        if diff <= 0.33 * self.frame.size.height {
            shapeLayer1.path = aPath.cgPath
            shapeLayer1.strokeColor = #colorLiteral(red: 0.937254902, green: 0.5058823529, blue: 0.4941176471, alpha: 1).cgColor
            shapeLayer1.lineWidth = internalLineWidth
            shapeLayer1.zPosition = 2.0
        }
        else if (diff <= self.frame.size.height * 0.66 && diff >= 0.33 * self.frame.size.height) {
            shapeLayer2.path = aPath.cgPath
            shapeLayer2.strokeColor = #colorLiteral(red: 0.7882352941, green: 0.3647058824, blue: 0.3529411765, alpha: 1).cgColor
            shapeLayer2.lineWidth = internalLineWidth
            shapeLayer1.zPosition = 0.0
            shapeLayer3.zPosition = 1.0
            shapeLayer2.zPosition = 2.0
        }
        else if (diff >= 0.67 * self.frame.size.height)
        {
            shapeLayer3.path = aPath.cgPath
            shapeLayer3.strokeColor = #colorLiteral(red: 0.7294117647, green: 0.1610280275, blue: 0.1210218742, alpha: 1).cgColor
            shapeLayer3.lineWidth = internalLineWidth
            shapeLayer2.zPosition = 1.0
            shapeLayer1.zPosition = 0.0
            shapeLayer3.zPosition = 2.0
        }
        xPoint += internalLineSeperation
        xPoint += internalLineWidth
    }
}
//    func addOverlayLabels() {
//        let values : [String] = ["0", "-1", "-3", "-6", "-7", "-10"]
//        var valuesFinal : [String] = values
//        valuesFinal += values.reversed()
//        for i in 0...11{
//            let topLabel = UILabel.init(frame: CGRect.init(x: 2, y: CGFloat(i) * self.frame.size.height / 12.0 - self.frame.size.height / 17.25, width: self.frame.size.height / 12.0, height: self.frame.size.height / 12.0))
//            topLabel.center.y = 5 + CGFloat(i) * self.frame.size.height / 12.0
//            topLabel.text = "\(valuesFinal[i]) dB"
//            topLabel.textAlignment = .center
//            topLabel.textColor = self.invertColor(self.backgroundColor!)
//            topLabel.adjustsFontSizeToFitWidth = true
//            self.addSubview(topLabel)
//        }
//    }
/*func reduce(_ val : CGFloat, _ amount : CGFloat?) -> CGFloat {
 if amount == nil {
 return (val * 0.9 * amount!)
 }
 return (val * 0.9 * 0.1)
 }*/
