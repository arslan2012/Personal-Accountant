import Foundation

private struct RateCacheEntry: Codable {
    let data: Data
    let timestamp: Date
}

private struct SupportedCurrenciesCache: Codable {
    let codes: [String]
    let timestamp: Date
}

class CurrencyExchange {
    static let shared = CurrencyExchange()
    
    private let primaryBaseURL = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/"
    private let fallbackBaseURL = "https://latest.currency-api.pages.dev/v1/currencies/"
    private let rateCacheExpiry: TimeInterval = 12 * 60 * 60 // 12 hours
    private let currencyListCacheExpiry: TimeInterval = 24 * 60 * 60 // 24 hours
    
    // In-memory cache
    private var rateCache: [String: RateCacheEntry] = [:]
    private var supportedCurrenciesCache: SupportedCurrenciesCache? = nil
    
    // UserDefaults keys
    private let rateCacheKey = "CurrencyExchangeRateCache"
    private let currencyListCacheKey = "CurrencyExchangeSupportedCurrenciesCache"
    
    private init() {
        loadRateCache()
        loadSupportedCurrenciesCache()
    }
    
    private func loadRateCache() {
        if let data = UserDefaults.standard.data(forKey: rateCacheKey),
           let dict = try? JSONDecoder().decode([String: RateCacheEntry].self, from: data) {
            rateCache = dict
        }
    }
    private func saveRateCache() {
        if let data = try? JSONEncoder().encode(rateCache) {
            UserDefaults.standard.set(data, forKey: rateCacheKey)
        }
    }
    
    private func loadSupportedCurrenciesCache() {
        if let data = UserDefaults.standard.data(forKey: currencyListCacheKey),
           let obj = try? JSONDecoder().decode(SupportedCurrenciesCache.self, from: data) {
            supportedCurrenciesCache = obj
        }
    }
    private func saveSupportedCurrenciesCache() {
        if let cache = supportedCurrenciesCache,
           let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: currencyListCacheKey)
        }
    }
    
    /// Fetches the exchange rate from one currency to another.
    /// - Parameters:
    ///   - from: The base currency code (e.g., "usd").
    ///   - to: The target currency code (e.g., "eur").
    ///   - completion: Completion handler with the exchange rate or error.
    func fetchExchangeRate(from: String, to: String, completion: @escaping (Result<Double, Error>) -> Void) {
        let fromLower = from.lowercased()
        let toLower = to.lowercased()
        // Check cache
        if let cached = rateCache[fromLower], Date().timeIntervalSince(cached.timestamp) < rateCacheExpiry {
            if let baseDict = try? JSONSerialization.jsonObject(with: cached.data) as? [String: Any],
               let rate = parseRateFromDict(baseDict, toLower) {
                completion(.success(rate))
                return
            }
        }
        let urlString = "\(primaryBaseURL)\(fromLower).json"
        print("[CurrencyConversion] Primary URL: \(urlString)")
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let rate = self.parseRate(data: data, from: fromLower, to: toLower) {
                self.rateCache[fromLower] = RateCacheEntry(data: data, timestamp: Date())
                self.saveRateCache()
                completion(.success(rate))
            } else {
                // Try fallback
                self.fetchExchangeRateFallback(from: fromLower, to: toLower, completion: completion)
            }
        }
        task.resume()
    }
    
    private func fetchExchangeRateFallback(from: String, to: String, completion: @escaping (Result<Double, Error>) -> Void) {
        let urlString = "\(fallbackBaseURL)\(from).json"
        print("[CurrencyConversion] Fallback URL: \(urlString)")
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid fallback URL", code: 0)))
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let rate = self.parseRate(data: data, from: from, to: to) {
                self.rateCache[from] = RateCacheEntry(data: data, timestamp: Date())
                self.saveRateCache()
                completion(.success(rate))
            } else {
                completion(.failure(error ?? NSError(domain: "Failed to fetch exchange rate", code: 0)))
            }
        }
        task.resume()
    }
    
    private func parseRate(data: Data, from: String, to: String) -> Double? {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let baseDict = json[from] as? [String: Any] {
                return parseRateFromDict(baseDict, to)
            }
        } catch {
            return nil
        }
        return nil
    }
    
    private func parseRateFromDict(_ dict:[String: Any], _ to:String) -> Double? {
        if let rate = dict[to] as? Double {
            return rate
        } else if let rateNum = dict[to] as? NSNumber {
            return rateNum.doubleValue
        }
        return nil
    }
    
    /// Converts an amount from one currency to another.
    /// - Parameters:
    ///   - amount: The amount in the base currency.
    ///   - from: The base currency code.
    ///   - to: The target currency code.
    ///   - completion: Completion handler with the converted amount or error.
    func convert(amount: Double, from: String, to: String, completion: @escaping (Result<Double, Error>) -> Void) {
        fetchExchangeRate(from: from, to: to) { result in
            switch result {
            case .success(let rate):
                completion(.success(amount * rate))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Fetches the list of supported currency codes.
    static func fetchSupportedCurrencies(completion: @escaping (Result<[String], Error>) -> Void) {
        // Try cache first
        if let cache = CurrencyExchange.shared.supportedCurrenciesCache, Date().timeIntervalSince(cache.timestamp) < CurrencyExchange.shared.currencyListCacheExpiry {
            completion(.success(cache.codes))
            return
        }
        let urlString = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies.json"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let codes = Array(json.keys).map { $0.uppercased() }.sorted()
                        CurrencyExchange.shared.supportedCurrenciesCache = SupportedCurrenciesCache(codes: codes, timestamp: Date())
                        CurrencyExchange.shared.saveSupportedCurrenciesCache()
                        completion(.success(codes))
                    } else {
                        completion(.failure(NSError(domain: "Invalid JSON", code: 0)))
                    }
                } catch {
                    completion(.failure(error))
                }
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "Unknown error", code: 0)))
            }
        }
        task.resume()
    }
} 
