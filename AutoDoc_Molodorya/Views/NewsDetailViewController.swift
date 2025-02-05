//
//  NewsDetailViewController.swift
//  AutoDoc_Molodorya
//
//  Created by Nikita Molodorya on 04.02.2025.
//

import UIKit
import WebKit
import SafariServices

/// Контроллер детального просмотра новости.
/// Позволяет пользователю переключаться между встроенным режимом (WKWebView) и режимом браузера (SFSafariViewController)
class NewsDetailViewController: UIViewController {

    // MARK: - Свойства
    
    /// Модель новости, содержащая данные для отображения.
    private let newsItem: NewsItem
    
    /// Встроенный веб-просмотр (WKWebView) для загрузки страницы новости.
    private var webView: WKWebView!
    
    /// Флаг режима: false – показываем WKWebView, true – открываем SFSafariViewController.
    private var isSafariMode = false
    
    // MARK: - Инициализация
    
    /// Инициализатор контроллера с моделью новости.
    init(newsItem: NewsItem) {
        self.newsItem = newsItem
        super.init(nibName: nil, bundle: nil)
        self.title = newsItem.title // Заголовок экрана совпадает с заголовком новости.
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Настройка и добавление WKWebView на экран.
        setupWebView()
        // Загружаем веб-страницу с URL новости.
        loadWebPage()
        
        // Настраиваем внешний вид навигационной панели: задаем непрозрачный фон и белый цвет.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground() // Отключает прозрачность навигационной панели.
        appearance.backgroundColor = .white         // Устанавливаем нужный цвет.
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        // Добавляем кнопку переключения режима просмотра на правой стороне навигационной панели.
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Safari",        // Начальное название кнопки (отражает режим, в который перейдет при нажатии).
            style: .plain,
            target: self,
            action: #selector(toggleViewMode)
        )
    }
    
    // MARK: - Настройка WebView
    
    /// Создает и настраивает WKWebView, добавляет его на view и задает ограничения (constraints).
    private func setupWebView() {
        webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // Устанавливаем белый фон, чтобы избежать просвечивания содержимого.
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        
        view.addSubview(webView)
        
        // Авто layout: привязываем WKWebView к safeArea.
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    // MARK: - Загрузка веб-страницы
    
    /// Загружает веб-страницу новости в WKWebView по URL, взятому из модели.
    private func loadWebPage() {
        guard let url = URL(string: newsItem.fullUrl) else {
            print("Ошибка: некорректный URL - \(newsItem.fullUrl)")
            return
        }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    // MARK: - Переключение режима просмотра
    
    /// Метод-обработчик, вызываемый при нажатии на UIBarButtonItem. Переключает режим просмотра между WKWebView и SFSafariViewController.
    @objc private func toggleViewMode() {
        isSafariMode.toggle() // Переключаем флаг режима
        
        if isSafariMode {
            // Если выбран режим Safari, открываем SFSafariViewController.
            openInSafari()
        } else {
            // Если выбран режим WebView, возвращаем WKWebView.
            navigationItem.rightBarButtonItem?.title = "Safari"
            // Если SFSafariViewController был открыт модально, закрываем его.
            dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Открытие в SafariViewController
    
    /// Открывает веб-страницу в SFSafariViewController, обновляет заголовок кнопки на "WebView".
    private func openInSafari() {
        guard let url = URL(string: newsItem.fullUrl) else {
            print("Ошибка: некорректный URL - \(newsItem.fullUrl)")
            return
        }
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor = .systemBlue // Настраиваем цвет элементов управления.
        present(safariVC, animated: true, completion: nil)
        
        // Обновляем заголовок кнопки, чтобы показать, что можно вернуться к режиму WebView.
        navigationItem.rightBarButtonItem?.title = "WebView"
    }
}
