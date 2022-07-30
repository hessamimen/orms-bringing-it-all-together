class Dog
    attr_accessor :name, :breed, :id

    def initialize(id: nil, name:, breed:)
        @name = name
        @breed = breed
        @id = id
    end
# creates the dogs table in the database
    def self.create_table
        sql = <<-SQL
            CREATE TABLE IF NOT EXISTS dogs (
                id INTEGER PRIMARY KEY,
                name TEXT,
                breed TEXT
            )
        SQL
        DB[:conn].execute(sql)
    end
# drops the dogs table from the database
    def self.drop_table 
        sql = "DROP TABLE IF EXISTS dogs"

        DB[:conn].execute(sql)
    end
# saves an instance of the dog class to the database and then sets the given dogs `id` attribute
# returns an instance of the dog class
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
# takes in a hash of attributes and uses metaprogramming to create a new dog object. Then it uses the #save method to save that dog to the database
# returns a new dog object
      def self.create(name:, breed:)
        dog = self.new(name:name, breed: breed)
        dog.save
        dog
      end
# creates an instance with corresponding attribute values
      def self.new_from_db(row)
        id = row[0]
        name = row[1]
        breed = row[2]
        self.new(id: id, name: name, breed: breed)
      end
# returns a new dog object by id
      def self.find_by_id(num)
        sql = <<-SQL
            SELECT * FROM dogs
            WHERE id = ?
        SQL
        result = DB[:conn].execute(sql, num)[0]
        self.new(id: result[0], name: result[1], breed: result[2])
      end
# creates an instance of a dog if it does not already exist
# when two dogs have the same name and different breed, it returns the correct dog
# when creating a new dog with the same name as persisted dogs, it returns the correct dog

      def self.find_or_create_by(name:, breed:)
        sql = <<-SQL
            SELECT * FROM dogs 
            WHERE name = ? 
            AND breed = ?
            LIMIT 1
        SQL
        dog = DB[:conn].execute(sql, name, breed)
        if !dog.empty?
            dog_info = dog[0]
            dog = self.new(id: dog_info[0],name: dog_info[1], breed: dog_info[2])
        else
            dog = self.create(name:name, breed: breed)
        end
            dog
      end

      def self.find_by_name(name)

        sql = <<-SQL
            SELECT * FROM dogs
            WHERE name = ?
        SQL
        dog = DB[:conn].execute(sql, name)[0]
        self.new(id: dog[0], name: dog[1], breed: dog[2])

      end

      def update
        sql = <<-SQL
            UPDATE dogs
            SET name = ?, breed = ?
            WHERE id = ?
        SQL
        DB[:conn].execute(sql, self.name, self.breed, self.id)
      end
end
