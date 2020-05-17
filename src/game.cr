require "prism"

module TutorialGame
  include Prism
  class Game < Prism::GameEngine
    alias Color = Prism::Maths::Vector3f

    def load_entity(name : String)
      load_entity(name) do
      end
    end

    # Loads a texture from the resources
    def load_texture(name : String)
      texture = Prism::Texture.load(File.join(__DIR__, "./res/textures/#{name}.png"))
      texture
    end

    # Loads a model from the resources and attaches it's material
    def load_model(name : String) : Prism::TexturedModel
      texture = load_texture(name)
      mesh = Prism::Model.load(File.join(__DIR__, "./res/models/#{name}.obj"))
      Prism::TexturedModel.new(mesh, texture)
    end

    # Generates a new entity with a model and textures
    # You can optionally provide a material
    def load_entity(name : String, &modify_material : -> Prism::Material | Nil) : Prism::Entity
      model = load_model(name)
      object = Prism::Entity.new
      object.name = name
      object.add model
      if material = modify_material.call
        object.add material.as(Prism::Material)
      end
      object
    end

    def seed(name : String, terrain : Prism::Entity, scale : Float32)
      seed(name, terrain, scale) do
      end
    end

    # Seeds the game with some objects
    def seed(name : String, terrain : Prism::Entity, scale : Float32, &modify_material : -> Prism::Material | Nil)
      model = load_model(name)
      random = Random.new
      0.upto(200) do |i|
        x : Float32 = random.next_float.to_f32 * 800 # the terrain is 800x800
        z : Float32 = random.next_float.to_f32 * 800

        y : Float32 = terrain.get(Prism::Terrain).as(Prism::Terrain).height_at(x, z)
        e = Prism::Entity.new
        e.add model
        if material = modify_material.call
          e.add material.as(Prism::Material)
        end
        e.transform.move_to(x, y, z).scale((random.next_float.to_f32 + 0.5) * scale)
        # hack to load fern texture atlas
        if name === "fern"
          e.add Prism::TextureOffset.new(2, rand(4).to_u32)
        end
        add_entity e
      end
    end

    def load_cube_map_texture(name : String) : Prism::TextureCubeMap
      Prism::Texture.load_cube_map(StaticArray[
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
        Prism::Skybox::Period.new(Prism::Skybox::Time.new(hour: 5), load_cube_map_texture("day")),
        Prism::Skybox::Period.new(Prism::Skybox::Time.new(hour: 17), load_cube_map_texture("night")),
      ]
      skybox.add Prism::InputSubscriber.new
      skybox.add Prism::Skybox.new(sky_periods, 30)
      add_entity skybox

      # Generate the terrain
      texture_pack = Prism::TerrainTexturePack.new(
        background: Prism::Texture.load_2d(File.join(__DIR__, "./res/textures/grassy2.png")),
        blend_map: Prism::Texture.load_2d(File.join(__DIR__, "./res/textures/blendMap.png")),
        red: Prism::Texture.load_2d(File.join(__DIR__, "./res/textures/mud.png")),
        green: Prism::Texture.load_2d(File.join(__DIR__, "./res/textures/grassFlowers.png")),
        blue: Prism::Texture.load_2d(File.join(__DIR__, "./res/textures/path.png"))
      )
      terrain = Prism::ModelData.generate_terrain(0, 0, File.join(__DIR__, "./res/textures/heightmap.png"), texture_pack)
      add_entity terrain

      # Add a merchant stall
      stall = load_entity("stall")
      stall.transform.move_north(65).move_east(55).elevate_to(terrain.get(Prism::Terrain).as(Prism::Terrain).height_at(stall))
      add_entity stall

      # add a tree
      tree = load_entity("lowPolyTree")
      tree.transform.move_north(55).move_east(60).elevate_to(terrain.get(Prism::Terrain).as(Prism::Terrain).height_at(tree))
      tree.material.wire_frame = true
      add_entity tree

      # Add some sunlight
      sun = Prism::Entity.new
      sun.add Prism::PointLight.new(Vector3f.new(0.2, 0.2, 0.2))
      sun.transform.move_to(0, 10000, -7000)
      add_entity sun

      # Add lamps
      lamp_model = load_model("lamp")
      red_lamp = Prism::Entity.new
      red_lamp.material.use_fake_lighting = true
      red_lamp.add lamp_model
      red_lamp.transform.move_north(65).move_east(50).elevate_to(terrain.get(Prism::Terrain).as(Prism::Terrain).height_at(red_lamp))
      add_entity red_lamp

      green_lamp = Prism::Entity.new
      green_lamp.material.use_fake_lighting = true
      green_lamp.add lamp_model
      green_lamp.transform.move_north(130).move_east(50).elevate_to(terrain.get(Prism::Terrain).as(Prism::Terrain).height_at(green_lamp))
      add_entity green_lamp

      yellow_lamp = Prism::Entity.new
      yellow_lamp.material.use_fake_lighting = true
      yellow_lamp.add lamp_model
      yellow_lamp.transform.move_north(190).move_east(50).elevate_to(terrain.get(Prism::Terrain).as(Prism::Terrain).height_at(yellow_lamp))
      add_entity yellow_lamp

      # Add lamp light
      red_light = Prism::Entity.new
      red_light.add Prism::PointLight.new(Vector3f.new(2, 0, 0), Prism::Attenuation.new(1, 0.01, 0.002))
      red_light.transform.move_to(red_lamp).elevate_by(15)
      add_entity red_light

      green_light = Prism::Entity.new
      green_light.add Prism::PointLight.new(Vector3f.new(0, 2, 2), Prism::Attenuation.new(1, 0.01, 0.002))
      green_light.transform.move_to(green_lamp).elevate_by(15)
      add_entity green_light

      yellow_light = Prism::Entity.new
      yellow_light.add Prism::PointLight.new(Vector3f.new(2, 2, 0), Prism::Attenuation.new(1, 0.01, 0.002))
      yellow_light.transform.move_to(yellow_lamp).elevate_by(15)
      add_entity yellow_light

      # Generate a bunch of random trees
      seed("tree", terrain, 8)

      # Generate a bunch of random ferns
      seed("fern", terrain, 1) do
        m = Prism::Material.new
        m.has_transparency = true
        m
      end

      person = Prism::Entity.new
      person.add load_model("person")
      person.add Prism::PlayerMovement.new
      # Disable this for first person view
      person.add Prism::CameraControls::ThirdPerson.new(Vector3f.new(0, 10, 0))
      person.transform.move_north(32).move_east(32).elevate_to(20)
      person.add Prism::Camera.new
      add_entity person

      gui_entity = Prism::Entity.new
      gui_entity.add Prism::GUIElement.new(load_texture("health"), Vector2f.new(-0.75, 0.95), Vector2f.new(0.25, 0.25))
      add_entity gui_entity

      # Enable this (and disable the person above) to enable a free flying camera
      # camera = Prism::GhostCamera.new
      # camera.add Prism::Transform.new.look_at(stall).move_north(30).move_east(30).elevate_to(20)
      # add_entity camera

      # Generate a bunch of random cubes to test performance
      # random = Random.new
      # 0.upto(1000) do |i|
      #   x : Float32 = random.next_float.to_f32 * 800
      #   y : Float32 = random.next_float.to_f32 * 100
      #   z : Float32 = random.next_float.to_f32 * 800
      #   e = Prism::Entity.new
      #   e.add cube_model
      #   e.add Prism::Material.new
      #   e.add Prism::Transform.new(x, y, z)
      #   add_entity e
      # end
    end
  end
end
