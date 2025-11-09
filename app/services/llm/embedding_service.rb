# frozen_string_literal: true

# Service pour créer et gérer les embeddings de texte
# Utilise le script Python embedding_service.py
module Llm
  class EmbeddingService
    EMBEDDING_SCRIPT_PATH = Rails.root.join("..", "llm", "embedding_service.py").to_s.freeze
    DEFAULT_MODEL = "nomic-ai/nomic-embed-text-v1".freeze
    # Alternative: 'BAAI/bge-large-en-v1.5'

    class << self
      # Crée un embedding pour un texte donné
      # @param text [String] Le texte à encoder
      # @param model [String] Le modèle à utiliser (optionnel)
      # @return [Hash] Hash avec :embedding (array), :dimension (integer), :text (string)
      def create_embedding(text, model: nil)
        new.create_embedding(text, model: model)
      end

      # Crée des embeddings pour plusieurs textes
      # @param texts [Array<String>] Les textes à encoder
      # @param model [String] Le modèle à utiliser (optionnel)
      # @return [Array<Hash>] Array de hash avec :embedding, :dimension, :text
      def create_embeddings_batch(texts, model: nil)
        new.create_embeddings_batch(texts, model: model)
      end

      # Recherche les documents les plus similaires
      # @param query [String] La requête de recherche
      # @param index_path [String] Chemin vers l'index FAISS
      # @param k [Integer] Nombre de résultats à retourner
      # @return [Array<Hash>] Résultats avec :document, :score, :distance, :rank
      def search(query, index_path:, k: 5)
        new.search(query, index_path: index_path, k: k)
      end
    end

    def create_embedding(text, model: nil)
      model ||= DEFAULT_MODEL
      python_env = python_environment

      result = `#{python_env}python3 #{EMBEDDING_SCRIPT_PATH} embed --text "#{text.gsub('"', '\\"')}" --model #{model} 2>&1`

      parse_json_result(result)
    rescue StandardError => e
      Rails.logger.error("EmbeddingService error: #{e.message}")
      raise "Failed to create embedding: #{e.message}"
    end

    def create_embeddings_batch(texts, model: nil)
      texts.map { |text| create_embedding(text, model: model) }
    end

    def search(query, index_path:, k: 5)
      python_env = python_environment
      index_full_path = Rails.root.join("..", "llm", index_path).to_s

      result = `#{python_env}python3 #{EMBEDDING_SCRIPT_PATH} search --text "#{query.gsub('"', '\\"')}" --index "#{index_full_path}" --k #{k} 2>&1`

      parse_json_result(result)
    rescue StandardError => e
      Rails.logger.error("EmbeddingService search error: #{e.message}")
      raise "Failed to search embeddings: #{e.message}"
    end

    private

    def python_environment
      venv_path = Rails.root.join("..", "llm", "venv", "bin")
      venv_path.exist? ? "#{venv_path}/" : ""
    end

    def parse_json_result(result)
      # Extraire uniquement le JSON (ignorer les messages stderr)
      json_line = result.lines.find { |line| line.strip.start_with?("{") || line.strip.start_with?("[") }

      if json_line.nil?
        Rails.logger.error("No JSON found in result: #{result}")
        raise "Invalid response from embedding service"
      end

      JSON.parse(json_line.strip)
    rescue JSON::ParserError => e
      Rails.logger.error("JSON parse error: #{e.message}, result: #{result}")
      raise "Failed to parse embedding service response: #{e.message}"
    end
  end
end
