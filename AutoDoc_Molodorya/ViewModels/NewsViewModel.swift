//
//  NewsViewModel.swift
//  AutoDoc_Molodorya
//
//  Created by Nikita Molodorya on 04.02.2025.
//

import Foundation
import Combine
import UIKit

class NewsViewModel {
    // Публикуем новости для подписки во View
    @Published private(set) var newsItems: [NewsItem] = []
    @Published private(set) var isLoading: Bool = false

    // Параметры пагинации
    private var currentPage = 1
    private let pageSize = 15
    private var totalCount = 0
    
    // Хранение подписок Combine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    /// Метод для первичной загрузки данных
    func loadInitialNews() {
        currentPage = 1
        newsItems = []
        totalCount = 0
        Task { await fetchNews(page: currentPage) }
    }
    
    /// Метод для загрузки следующей страницы, если данные еще имеются
    func loadMoreNewsIfNeeded(currentIndex: Int) {
        if currentIndex >= newsItems.count - 5,
           newsItems.count < totalCount,
           !isLoading {
            currentPage += 1
            Task { await fetchNews(page: currentPage) }
        }
    }
    
    
    private func prefetchImages(for newsItems: [NewsItem]) {
        for newsItem in newsItems {
            // Запускаем задачу для каждой новости
            Task {
                // Если изображение уже в кеше, переходим к следующей новости
                if ImageCache.shared.image(for: newsItem.titleImageUrl) != nil {
                    return
                }
                // Загружаем изображение асинхронно
                if let image = await loadImage(from: newsItem.titleImageUrl) {
                    ImageCache.shared.setImage(image, for: newsItem.titleImageUrl)
                }
            }
        }
    }
    
    
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
    
    // MARK: - Private Methods
    
    private func fetchNews(page: Int) async {
        guard let url = URL(string: "https://webapi.autodoc.ru/api/news/\(page)/\(pageSize)") else { return }
        
        isLoading = true
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(NewsResponse.self, from: data)
            
            await MainActor.run {
                self.totalCount = response.totalCount
                self.newsItems.append(contentsOf: response.news)
                self.isLoading = false
            }
            
            // Предзагружаем изображения для полученных новостей
            prefetchImages(for: response.news)
            
        } catch {
            await MainActor.run { self.isLoading = false }
            print("Ошибка загрузки новостей: \(error)")
        }
    }
}
