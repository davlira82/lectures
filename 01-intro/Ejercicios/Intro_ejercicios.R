
# Ejercicios iniciales para aprender a usar ggplot2 ---------------------------------



# Cargar paquetes con la biblioteca "pacman"
pacman::p_load(ggplot2, gapminder,gifski)

# Algunos gráficos

ggplot(data = gapminder, aes(x = gdpPercap, y = lifeExp, linewidth = pop, col = continent)) +
  geom_point(alpha = 0.3)  +
  geom_smooth(method = "loess") # al establecer un mapeo general, las capas geométricas se ejecutan de acuerdo a esos parámetros

# Si la intención es que cada geometría lleve a cabo una visualización específica, se define un mapeo para cada capa geométrica
ggplot(data = gapminder) + ## i.e. No "global" aesthetic mappings"
geom_density(aes(x = gdpPercap, fill = continent), alpha=0.3)

# Ejemplo de superposición de capas geométricas

p = ggplot(data = gapminder, aes(x = gdpPercap, y = lifeExp))

p2 =
  p +
  geom_point(aes(size = pop, col = continent), alpha = 0.3) +
  scale_color_brewer(name = "Continent", palette = "Set1") + ## Different colour scale
  scale_size(name = "Population", labels = scales::comma) + ## Different point (i.e. legend) scale
  scale_x_log10(labels = scales::dollar) + ## Switch to logarithmic scale on x-axis. Use dollar units.
  labs(x = "Log (GDP per capita)", y = "Life Expectancy") + ## Better axis titles
  theme_minimal() ## Try a minimal (b&w) plot theme

p2

# Ejemplo de gráficos con ggplor que integran bibliotecas gráficas adicionales 

pacman::p_load(hrbrthemes, gganimate)

## Ejemplo de uso de temas
p2 + theme_modern_rc() + geom_point(aes(size = pop, col = continent), alpha = 0.2)

## Ejemplo animado
p3 <- ggplot(gapminder, aes(gdpPercap, lifeExp, size = pop, colour = country)) +
  geom_point(alpha = 0.7, show.legend = FALSE) +
  scale_colour_manual(values = country_colors) +
  scale_size(range = c(2, 12)) +
  scale_x_log10() +
  facet_wrap(~continent) +
  # Here comes the gganimate specific bits
  labs(title = 'Year: {frame_time}', x = 'GDP per capita', y = 'life expectancy') +
  transition_time(year) +
  ease_aes('linear')
  
animate(p3, renderer = gifski_renderer())




