#! /usr/bin/env ruby
# encoding: utf-8

require 'iconv'
require 'yaml'
require 'erb'

# Permettre d'avoir une chaine de caractère avec une longueur max
class String
  def normalize_text(length)
    if self.length > length
      self[0..length-4] + "..."
    else
      self
    end
  end
end

class SiteGenerator
  def initialize()
    @tree = {}
    @parent_matrice = {}
    @destination_path = ""
    yml_file = "parameters.yml"

    check_file yml_file
    # Chargement des paramètres du fichier parameters.yml
    if File.exist? yml_file
      @parameters = YAML::load(File.open(yml_file))
    end

    @destination_path = @parameters[:destination_path] + File::SEPARATOR unless @parameters[:destination_path].nil? 

    unless @parameters[:images_dir].nil? 
      @images_dir = @destination_path + @parameters[:images_dir]
    else
      @images_dir = @destination_path + "images"
    end

    @filein = @parameters[:filein]
    @template = @parameters[:template]
    check_dir @images_dir
    check_file @filein
    check_file @template

    construct_tree()

    get_slide_count
    @sommaire = parse_tree

    generate_pages
  end

  def check_file(file)
    unless File.exist? file
      puts "Il manque le fichier : #{file}"
      exit
    end
  end

  def check_dir(file)
    unless File.exist? file
      puts "Il manque le répertoire : #{file}"
      exit
    end
  end

  # Permet de detecter l'arborescence à partir d'un fichier texte
  def construct_tree()
    parent = "0"
    level_previous = level = 0
    pagen_previous = page = 0
    direction = 0
    text = ""

    File.open(@filein).each { |line|
      line = Iconv.conv("utf-8//TRANSLIT//IGNORE", "WINDOWS-1252", line)  # Convertir le fichier en UTF8
      line.gsub!(/\r.*/, '')                                              # Netoyer la ligne à partir du premier Ctrl-M jusqu'a la fin

      #                     1       2   3
      page = line.match /([0-9]*) (\t*)(.*)[ ]*$/                         # Extraire de la ligne : n° de page, les tabs (niveau) et le texte
      if page.nil? # Si la ligne est vide, passer à la suivante
        next
      end

      pagen = page[1]
      level_tab = page[2]
      text = page[3]
      level = level_tab.length  # compter les tabs pour avoir le niveau

      if level > level_previous # Si je monte dans l'arbre
          direction = 1
      elsif level < level_previous # Si je descend
          direction = -1
      else # Et sinon c'est surement que je reste au même niveau
          direction = 0
      end

      if direction > 0
        # Si je monte, j'ajoute le noeud precendent (parent) dans
        #une chaine qui contient la liste de mes parents
        # Ex : "0,13,27"
        parent += ",#{pagen_previous}"
      elsif direction < 0
        # Si je descend
        parent = parent.split(/,/)[0..-2].join(',')
      end

      @parent_matrice[pagen] = parent.split(/,/)[-1] # Ajouter le liens de parenté dans le hash parent_matrice
      # Ajouter dans le hash tree toutes les informations sur mon noeud courant
      @tree[pagen] = {:level => level, :level_tab => level_tab, :direction => direction, :text => text, :parent => parent.split(/,/)[-1]}

      level_previous = level
      pagen_previous = pagen
    }
  end

  def close_tree(current_level, last_level, prefix="")
    delta = current_level - last_level
    "#{prefix}</ul></li>" * delta.abs
  end

  def parse_tree
    lastlevel = 0
    result = "<ul>\n"

    @tree.keys.each { |page|
      direction = @tree[page][:direction]
      if direction < 0 # Si je descend
        result += close_tree(@tree[page][:level], lastlevel, @tree[page][:level_tab]) + "\n"
      end
      max_length = 25 - (@tree[page][:level] * 3)

      result += "#{@tree[page][:level_tab]}<li id=\"p#{page}\"><a href=\"page_#{page}.html\" title=\"#{@tree[page][:text]}\">#{@tree[page][:text].normalize_text(max_length)}</a>"

      if @parent_matrice.has_value?(page) # Si le noeud courant à des enfants ouvrir un ul
        result += "<ul>\n"
      else # Sinon c'est un noeud normal
        result += "</li>\n"
      end

      lastlevel = @tree[page][:level]
    }

    result += close_tree(0, lastlevel)
    result += "</ul>\n"
  end

  def get_slide_count
    # Permet de compter les images (.PNG) dans "images/"
    @slide_count = 0
    Dir.foreach(@images_dir).sort.each { |file|
      if file =~ /.PNG$/
        @slide_count += 1
      end
    }
  end

  def generate_pages
    template = File.open(@template).readlines.join.force_encoding("UTF-8")

    slide_count = @slide_count
    (1..slide_count).each { |i|
      @current_page = i
      html_name = "#{@destination_path}page_#{@current_page}.html"

      if @parent_matrice.has_value?(@current_page.to_s) # Si je suis un noeud parent je suis ouvert
        @node_opened = @current_page
      else # Si je suis un noeud simple, c'est mon père qui est ouvert
        @node_opened = @parent_matrice[@current_page.to_s]
      end

      File.open(html_name, 'w').puts ERB.new(template).result(self.get_binding)
    }
  end

  # Expose private binding() method.
  # http://www.stuartellis.eu/articles/erb/
  def get_binding
    binding()
  end
end

site = SiteGenerator.new()
