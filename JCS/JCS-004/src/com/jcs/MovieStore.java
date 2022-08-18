package com.jcs;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

public class MovieStore {
   private static List<Movie> movies = new ArrayList<>();
   static {
      movies.add(new Movie("Whisper of the Heart", 1995, "Yoshifumi Kondo", 94));
      movies.add(new Movie("Earwig and the Witch", 2020, "Goro Miyazaki", 30));
      movies.add(new Movie("Spirited Away", 2001, "Hayao Miyazaki", 97));
      movies.add(new Movie("From Up on Poppy Hill", 2011, "Goro Miyazaki", 86));
      movies.add(new Movie("Ocean Waves", 1993, "Tomomi Mochizuki", 88));
      movies.add(new Movie("Princess Mononoke", 1997, "Hayao Miyazaki", 93));
      movies.add(new Movie("Castle in the Sky", 1986, "Hayao Miyazaki", 96));
      movies.add(new Movie("When Marnie Was There", 2014, "Hiromasa Yonebayashi", 91));
      movies.add(new Movie("The Cat Returns", 2002, "Hiroyuki Morita", 91));
      movies.add(new Movie("The Tale of the Princess Kaguya", 2013, "Isao Takahata", 100));
      movies.add(new Movie("Pom Poko", 1994, "Isao Takahata", 85));
      movies.add(new Movie("Kiki's Delivery Service", 1989, "Hayao Miyazaki", 98));
      movies.add(new Movie("My Neighbor Totoro", 1988, "Hayao Miyazaki", 94));
      movies.add(new Movie("My Neighbors the Yamadas", 1999, "Isao Takahata", 78));
      movies.add(new Movie("Only Yesterday", 1991, "Isao Takahata", 100));
      movies.add(new Movie("Arrietty", 2010, "Hiromasa Yonebayashi", 95));
      movies.add(new Movie("Grave of the Fireflies", 1988, "Isao Takahata", 100));
      movies.add(new Movie("Tales from Earthsea", 2006, "Goro Miyazaki", 43));
      movies.add(new Movie("The Wind Rises", 2013, "Hayao Miyazaki", 88));
      movies.add(new Movie("Howl's Moving Castle", 2004, "Hayao Miyazaki", 87));
      movies.add(new Movie("Porco Rosso", 1992, "Hayao Miyazaki", 95));
      movies.add(new Movie("Ponyo", 2008, "Hayao Miyazaki", 91));

   }

   public static List<Movie> getMovies(){
      return movies;
   }
}
