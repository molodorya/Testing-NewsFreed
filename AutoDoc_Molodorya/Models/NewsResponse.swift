//
//  NewsResponse.swift
//  AutoDoc_Molodorya
//
//  Created by Nikita Molodorya on 04.02.2025.
//

import Foundation

struct NewsResponse: Codable {
    let news: [NewsItem]
    let totalCount: Int
}
