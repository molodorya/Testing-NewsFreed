//
//  NewsCell.swift
//  AutoDoc_Molodorya
//
//  Created by Nikita Molodorya on 04.02.2025.
//

import UIKit
import SafariServices

class NewsCell: UICollectionViewCell {

    // MARK: - IBOutlets
    // Подключенные из Storyboard элементы:
    @IBOutlet weak var titleView: UILabel!           // Отображает заголовок новости.
    @IBOutlet weak var descriptionLabel: UILabel!    // Отображает краткое описание.
    @IBOutlet weak var dateLabel: UILabel!           // Показывает отформатированную дату публикации.
    @IBOutlet weak var categoryLabel: UILabel!       // Отображает категорию новости.
    @IBOutlet weak var imageView: UIImageView!       // Показывает основное изображение новости.
    @IBOutlet weak var gradientView: UIView!         // Контейнер для градиентного слоя, накладываемого поверх изображения.
    @IBOutlet weak var onceView: UIView!             // View с округленными углами (например, для оформления ячейки).

    // MARK: - Свойства для оформления
    private let gradientLayer = CAGradientLayer()    // Градиентный слой для наложения затемнения.
    
    // Храним URL текущего загружаемого изображения для проверки, чтобы при переиспользовании ячейки не установить неактуальное изображение.
    private var currentImageUrl: String?
    
    // MARK: - Жизненный цикл ячейки
    override func awakeFromNib() {
        super.awakeFromNib()
        // Настраиваем округление углов для onceView
        onceView.layer.cornerRadius = 30
        onceView.clipsToBounds = true
        // Настраиваем градиент, который будет наложен на gradientView.
        setupGradient()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Обновляем размер градиента, чтобы он соответствовал размерам gradientView.
        gradientLayer.frame = gradientView.bounds
    }
    
    // MARK: - Настройка градиента
    /// Метод setupGradient() настраивает градиентный слой для gradientView.
    /// Здесь задаются цвета, точки начала и конца градиента, чтобы создать плавное затемнение от более прозрачного (вверху) к более темному (внизу).
    private func setupGradient() {
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.2).cgColor, // Верхняя часть: слегка затемненная.
            UIColor.black.withAlphaComponent(0.5).cgColor  // Нижняя часть: более темная.
        ]
        gradientLayer.locations = [0.0, 1.0]             // Градиент распространяется от начала до конца.
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0) // Начинается по центру сверху.
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)   // Заканчивается по центру снизу.
        
        // Вставляем градиентный слой в gradientView на задний план (индекс 0).
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    // MARK: - Конфигурация ячейки
    /// Метод configure(with:) заполняет ячейку данными новости.
    /// Он устанавливает текстовые данные и асинхронно загружает изображение, используя async/await.
    func configure(with newsItem: NewsItem) {
        // Устанавливаем текстовые данные
        titleView.text = newsItem.title
        descriptionLabel.text = newsItem.description.isEmpty ? "Описание отсутствует" : newsItem.description
        dateLabel.text = formatDate(from: newsItem.publishedDate) ?? "Дата неизвестна"
        categoryLabel.text = newsItem.categoryType
        
        // Сохраняем URL изображения для проверки при переиспользовании ячейки.
        currentImageUrl = newsItem.titleImageUrl
        
        // Очищаем изображение, чтобы избежать мерцания при переиспользовании.
        imageView.image = nil
        
        // Запускаем асинхронную задачу для загрузки изображения.
        Task {
            // Сначала проверяем, есть ли изображение в кеше.
            if let cachedImage = ImageCache.shared.image(for: newsItem.titleImageUrl) {
                await MainActor.run {
                    self.imageView.image = cachedImage
                }
                return
            }
            
            // Если изображения нет в кеше, загружаем его асинхронно.
            if let image = await loadImage(from: newsItem.titleImageUrl) {
                // Кешируем полученное изображение.
                ImageCache.shared.setImage(image, for: newsItem.titleImageUrl)
                
                // Перед установкой изображения проверяем, что ячейка все еще предназначена для этого URL.
                if self.currentImageUrl == newsItem.titleImageUrl {
                    await MainActor.run {
                        self.imageView.image = image
                    }
                }
            }
        }
    }
    
    // MARK: - Асинхронная загрузка изображения
    /// Функция loadImage(from:) асинхронно загружает изображение по заданному URL.
    private func loadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("Ошибка загрузки изображения: \(error)")
            return nil
        }
    }
    
    // MARK: - Форматирование даты
    /// Функция formatDate(from:) преобразует строку даты из JSON в более читаемый формат.
    private func formatDate(from dateString: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss" // Формат, приходящий из JSON
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = dateFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "d MMMM yyyy" // Целевой формат отображения
            outputFormatter.locale = Locale(identifier: "ru_RU") // Локализация для русского языка
            return outputFormatter.string(from: date)
        }
        return nil
    }
}





/// Синглтон для кеширования изображений с использованием NSCache.
class ImageCache {
    static let shared = ImageCache()  // Единый экземпляр
    
    private init() { }
    
    private let cache = NSCache<NSString, UIImage>()
    
    /// Возвращает изображение для данного URL, если оно уже закешировано.
    func image(for url: String) -> UIImage? {
        return cache.object(forKey: url as NSString)
    }
    
    /// Сохраняет изображение в кеше по заданному URL.
    func setImage(_ image: UIImage, for url: String) {
        cache.setObject(image, forKey: url as NSString)
    }
}
