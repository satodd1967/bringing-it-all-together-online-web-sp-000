class Dog

    attr_accessor :name, :breed
    attr_reader :id

    def initialize(name:, breed:, id: nil)
        @name = name
        @breed = breed
        @id = id
    end

    def self.create_table
        sql =  <<-SQL
          CREATE TABLE IF NOT EXISTS dogs (
            id INTEGER PRIMARY KEY,
            name TEXT,
            breed TEXT
            )
            SQL
        DB[:conn].execute(sql)
      end

      def self.drop_table
        sql =  <<-SQL 
          DROP TABLE dogs
            SQL
        DB[:conn].execute(sql) 
      end

      def update
        sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?"
        DB[:conn].execute(sql, self.name, self.breed, self.id)
      end

      def save
        if self.id
          self.update
        else
          sql = <<-SQL
            INSERT INTO dogs (name, breed)
            VALUES (?, ?)
          SQL
          DB[:conn].execute(sql, self.name, self.breed)
          @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
        end
        self
      end

      def self.create(dog_hash)
        dog = Dog.new(name: dog_hash[:name], breed: dog_hash[:breed])
        dog.save
        dog
      end

      def self.new_from_db(row)
        new_dog = self.new(name: row[1], breed: row[2], id: row[0])
        new_dog
      end

      def self.find_by_id(id)
        sql = <<-SQL
          SELECT *
          FROM dogs
          WHERE id = ?
        SQL
        found_dog = DB[:conn].execute(sql, id).flatten
        Dog.new(id: found_dog[0], name: found_dog[1], breed: found_dog[2])
    end

    def self.find_or_create_by(name:, breed:)
        sql = <<-SQL
        SELECT *
        FROM dogs
        WHERE name = ?
        AND breed = ?
        SQL
        dog = DB[:conn].execute(sql, name, breed).first
        if dog
            new_dog = self.new_from_db(dog)
        else
            new_dog = self.create({:name => name, :breed => breed})
        end
        new_dog
    end
    
    def self.find_by_name(name)
        sql = <<-SQL
          SELECT *
          FROM dogs
          WHERE name = ?
          LIMIT 1
        SQL
     
        DB[:conn].execute(sql, name).map do |row|
          self.new_from_db(row)
        end.first
      end

end
