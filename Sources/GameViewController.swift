import UIKit
import WebKit
import AVFoundation

final class GameViewController: UIViewController, WKNavigationDelegate {
    private var web: WKWebView!

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .all }

    override func loadView() {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        // Dentro do app nativo: esconde a dica "Adicionar à Tela de Início" do site.
        let js = "Object.defineProperty(navigator,'standalone',{get:function(){return true}});"
        cfg.userContentController.addUserScript(
            WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true))

        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.navigationDelegate = self
        wv.isMultipleTouchEnabled = true   // modo 2 jogadores: vários dedos ao mesmo tempo
        wv.isOpaque = false
        wv.backgroundColor = .black
        wv.scrollView.backgroundColor = .black
        wv.scrollView.isScrollEnabled = false
        wv.scrollView.bounces = false
        wv.scrollView.contentInsetAdjustmentBehavior = .never
        web = wv
        view = wv
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Som toca mesmo com o iPhone no modo silencioso.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        NotificationCenter.default.addObserver(self, selector: #selector(pauseGame),
            name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeAudio),
            name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func pauseGame() {
        web.evaluateJavaScript("try{if(mode==='play')pause()}catch(e){}", completionHandler: nil)
    }

    @objc private func resumeAudio() {
        try? AVAudioSession.sharedInstance().setActive(true)
        web.evaluateJavaScript("try{if(au)au.resume()}catch(e){}", completionHandler: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("try{document.getElementById('bf').hidden=true}catch(e){}", completionHandler: nil)
    }

    // Bloqueia qualquer navegação para fora do jogo.
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(navigationAction.navigationType == .other ? .allow : .cancel)
    }
}
