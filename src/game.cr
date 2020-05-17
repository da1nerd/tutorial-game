require "prism"

module TutorialGame
  include Prism

  class Game < GameEngine
    alias Color = Maths::Vector3f

    def load_entity(name : String)
      load_entity(name) do
      end
    end

    # Loads a texture from the resources
    def load_texture(name : String)
      texture = Texture.load(File.join(__DIR__, "./res/textures/#{name}.png"))
      texture
    end

    # Loads a model from the resources and attaches it's material
    def load_model(name : String) : TexturedModel
      texture = load_texture(name)
      mesh = Model.load(File.join(__DIR__, "./res/models/#{name}.obj"))
      TexturedModel.new(mesh, texture)
    end

    # Generates a new entity with a model and textures
    # You can optionally provide a material
    def load_entity(name : String, &modify_material : -> Material | Nil) : Entity
      model = load_model(name)
      object = Entity.new
      object.name = name
      object.add model
      if material = modify_material.call
        object.add material.as(Material)
      end
      object
    end

    def seed(name : String, terrain : Entity, scale : Float32)
      seed(name, terrain, scale) do
      end
    end

    # Seeds the game with some objects
    def seed(name : String, terrain : Entity, scale : Float32, &modify_material : -> Material | Nil)
      model = load_model(name)
      random = Random.new
      0.upto(200) do |i|
        x : Float32 = random.next_float.to_f32 * 800 # the terrain is 800x800
        z : Float32 = random.next_float.to_f32 * 800

        y : Float32 = terrain.get(Terrain).as(Terrain).height_at(x, z)
        e = Entity.new
        e.add model
        if material = modify_material.call
          e.add material.as(Material)
        end
        e.transform.move_to(x, y, z).scale((random.next_float.to_f32 + 0.5) * scale)
        # hack to load fern texture atlas
        if name === "fern"
          e.add TextureOffset.new(2, rand(4).to_u32)
        end
        add_entity e
      end
    end

    def load_cube_map_texture(name : String) : TextureCubeMap
      Texture.load_cube_map(StaticArray[
        File.join(__DIR__, "./res/textures/#{name}Right.png"),
        File.join(__DIR__, "./res/textures/#{name}Left.png"),
        File.join(__DIR__, "./res/textures/#{name}Top.png"),
        File.join(__DIR__, "./res/textures/#{name}Bottom.png"),
        File.join(__DIR__, "./res/textures/#{name}Back.png"),
        File.join(__DIR__, "./res/textures/#{name}Front.png"),
      ])
    end

    def init
      skybox = Crash::Entity.new
      sky_periods = [
        Skybox::Period.new(Skybox::Time.new(hour: 5), load_cube_map_texture("day")),
        Skybox::Period.new(Skybox::Time.new(hour: 17), load_cube_map_texture("night")),
      ]
      skybox.add InputSubscriber.new
      skybox.add Skybox.new(sky_periods, 30)
      add_entity skybox

      # Generate the terrain
      texture_pack = TerrainTexturePack.new(
        background: Texture.load_2d(File.join(__DIR__, "./res/textures/grassy2.png")),
        blend_map: Texture.load_2d(File.join(__DIR__, "./res/textures/blendMap.png")),
        red: Texture.load_2d(File.join(__DIR__, "./res/textures/mud.png")),
        green: Texture.load_2d(File.join(__DIR__, "./res/textures/grassFlowers.png")),
        blue: Texture.load_2d(File.join(__DIR__, "./res/textures/path.png"))
      )
      terrain = ModelData.generate_terrain(0, 0, File.join(__DIR__, "./res/textures/heightmap.png"), texture_pack)
      add_entity terrain

      # Add a merchant stall
      stall = load_entity("stall")
      stall.transform.move_north(65).move_east(55).elevate_to(terrain.get(Terrain).as(Terrain).height_at(stall))
      add_entity stall

      # add a tree
      tree = load_entity("lowPolyTree")
      tree.transform.move_north(55).move_east(60).elevate_to(terrain.get(Terrain).as(Terrain).height_at(tree))
      tree.material.wire_frame = true
      add_entity tree

      # Add some sunlight
      sun = Entity.new
      sun.add PointLight.new(Vector3f.new(0.2, 0.2, 0.2))
      sun.transform.move_to(0, 10000, -7000)
      add_entity sun

      # Add lamps
      lamp_model = load_model("lamp")
      red_lamp = Entity.new
      red_lamp.material.use_fake_lighting = true
      red_lamp.add lamp_model
      red_lamp.transform.move_north(65).move_east(50).elevate_to(terrain.get(Terrain).as(Terrain).height_at(red_lamp))
      add_entity red_lamp

      green_lamp = Entity.new
      green_lamp.material.use_fake_lighting = true
      green_lamp.add lamp_model
      green_lamp.transform.move_north(130).move_east(50).elevate_to(terrain.get(Terrain).as(Terrain).height_at(green_lamp))
      add_entity green_lamp

      yellow_lamp = Entity.new
      yellow_lamp.material.use_fake_lighting = true
      yellow_lamp.add lamp_model
      yellow_lamp.transform.move_north(190).move_east(50).elevate_to(terrain.get(Terrain).as(Terrain).height_at(yellow_lamp))
      add_entity yellow_lamp

      # Add lamp light
      red_light = Entity.new
      red_light.add PointLight.new(Vector3f.new(2, 0, 0), Attenuation.new(1, 0.01, 0.002))
      red_light.transform.move_to(red_lamp).elevate_by(15)
      add_entity red_light

      green_light = Entity.new
      green_light.add PointLight.new(Vector3f.new(0, 2, 2), Attenuation.new(1, 0.01, 0.002))
      green_light.transform.move_to(green_lamp).elevate_by(15)
      add_entity green_light

      yellow_light = Entity.new
      yellow_light.add PointLight.new(Vector3f.new(2, 2, 0), Attenuation.new(1, 0.01, 0.002))
      yellow_light.transform.move_to(yellow_lamp).elevate_by(15)
      add_entity yellow_light

      # Generate a bunch of random trees
      seed("tree", terrain, 8)

      # Generate a bunch of random ferns
      seed("fern", terrain, 1) do
        m = Material.new
        m.has_transparency = true
        m
      end

      person = Entity.new
      person.add load_model("person")
      person.add PlayerMovement.new
      # Disable this for first person view
      person.add CameraControls::ThirdPerson.new(Vector3f.new(0, 10, 0))
      person.transform.move_north(32).move_east(32).elevate_to(20)
      person.add Camera.new
      add_entity person

      gui_entity = Entity.new
      gui_entity.add GUIElement.new(load_texture("health"), Vector2f.new(-0.75, 0.95), Vector2f.new(0.25, 0.25))
      add_entity gui_entity

      # Enable this (and disable the person above) to enable a free flying camera
      # camera = GhostCamera.new
      # camera.transform.look_at(stall).move_north(30).move_east(30).elevate_to(20)
      # add_entity camera

    end
  end
end
