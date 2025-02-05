//
//  NewsItem.swift
//  AutoDoc_Molodorya
//
//  Created by Nikita Molodorya on 04.02.2025.
//

import Foundation

struct NewsItem: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let publishedDate: String // Можно преобразовать в Date, если потребуется
    let url: String
    let fullUrl: String
    let titleImageUrl: String
    let categoryType: String
}
