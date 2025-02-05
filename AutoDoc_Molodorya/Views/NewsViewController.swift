//
//  ViewController.swift
//  AutoDoc_Molodorya
//
//  Created by Nikita Molodorya on 04.02.2025.
//

import UIKit
import Combine
import SafariServices

/// Контроллер главного экрана новостей. Отвечает за отображение списка новостей в UICollectionView, загрузку данных через ViewModel, а также за переключение режима открытия детального экрана (либо через SFSafariViewController, либо через NewsDetailViewController с WebView).
class NewsViewController: UIViewController {
    
    // MARK: - Свойства ViewModel и Combine
    
    /// Экземпляр ViewModel, отвечающий за загрузку и управление новостями.
    private let viewModel = NewsViewModel()
    
    /// Набор подписок (cancellables) для Combine, используемый для отмены подписок при деинициализации.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - IBOutlets
    
    /// Коллекция, созданная в Storyboard, для отображения списка новостей.
    @IBOutlet weak var collectionView: UICollectionView!
    
    /// Кнопка на навигационной панели, позволяющая переключать режим открытия детального экрана.
    @IBOutlet weak var changeDetailView: UIBarButtonItem!
    
    // MARK: - Режим отображения деталей
    
    /// Флаг, отвечающий за режим открытия детального экрана:
    /// false – открывается SFSafariViewController,
    /// true – открывается NewsDetailViewController (с WebView).
    private var isDetailViewEnabled = false
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Настройка интерфейса и подписок на обновления данных.
        setupUI()
        bindViewModel()
        // Загружаем первую страницу новостей.
        viewModel.loadInitialNews()
    }
     
    // MARK: - UI Setup
    
    /// Метод настройки пользовательского интерфейса.
    private func setupUI() {
        // Устанавливаем заголовок и внешний вид навигационной панели.
        title = "Новости"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground
        
        // Если делегаты и datasource не назначены через Storyboard, назначаем их программно.
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Устанавливаем кастомный layout для коллекции (Compositional Layout).
        collectionView.collectionViewLayout = createLayout()
        
        // Обновляем заголовок кнопки переключения режима.
        updateBarButtonTitle()
    }
    
    /// Метод подписки на изменения данных в ViewModel с использованием Combine.
    private func bindViewModel() {
        viewModel.$newsItems
            .receive(on: DispatchQueue.main) // Обновление UI на главном потоке.
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Переключение режима просмотра деталей
    
    /// IBAction, вызываемый при нажатии на UIBarButtonItem для переключения режима открытия детального экрана.
    @IBAction func changeDetailViewAction(_ sender: UIBarButtonItem) {
        // Переключаем режим: если был Detail, становится Safari, и наоборот.
        isDetailViewEnabled.toggle()
        updateBarButtonTitle()
    }
    
    /// Обновляет заголовок кнопки в зависимости от текущего режима.
    private func updateBarButtonTitle() {
        let newTitle = isDetailViewEnabled ? "Safari" : "Detail"
        changeDetailView.title = newTitle
    }
    
    // MARK: - Layout (Compositional Layout)
    
    /// Создает и возвращает UICollectionViewCompositionalLayout для коллекции новостей.
    /// Используется вертикальная группа, где каждый элемент занимает 100% ширины и имеет автоматическую (estimated) высоту.
    private func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            
            // 1. Элемент (Item): 100% ширины, высота рассчитывается автоматически.
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(200)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            // 2. Группа (Group): вертикальная группа, содержащая один элемент, занимающая 100% ширины коллекции.
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(200)
            )
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            // 3. Секция (Section): задаются отступы между группами и содержимым секции.
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 10
            section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            
            return section
        }
    }
}

// MARK: - UICollectionViewDataSource

extension NewsViewController: UICollectionViewDataSource {
    /// Возвращает количество элементов (новостей) для секции.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.newsItems.count
    }
    
    /// Конфигурирует и возвращает ячейку для новости.
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsCell", for: indexPath) as? NewsCell else {
            fatalError("Неверный тип ячейки")
        }
        let newsItem = viewModel.newsItems[indexPath.item]
        cell.configure(with: newsItem)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension NewsViewController: UICollectionViewDelegate {
    /// Обрабатывает выбор ячейки. В зависимости от текущего режима, открывает детальный экран либо через NewsDetailViewController (с WebView), либо через SFSafariViewController.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let newsItem = viewModel.newsItems[indexPath.item]
        
        if isDetailViewEnabled {
            // Режим Detail: переходим на детальный экран с использованием NewsDetailViewController.
            let detailVC = NewsDetailViewController(newsItem: newsItem)
            navigationController?.pushViewController(detailVC, animated: true)
        } else {
            // Режим Safari: открываем страницу новости в SFSafariViewController.
            if let url = URL(string: newsItem.fullUrl) {
                let safariVC = SFSafariViewController(url: url)
                present(safariVC, animated: true, completion: nil)
            } else {
                print("Некорректный URL: \(newsItem.fullUrl)")
            }
        }
    }
}
