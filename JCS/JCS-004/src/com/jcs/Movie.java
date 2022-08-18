package com.jcs;

import java.util.Objects;

public class Movie{
   private String title;
   private String director;
   private int score;
   private int year;

   public Movie(String title, int year, String director, int score){
      this.director = director;
      this.title = title;
      this.year = year;
      this.score = score;
   }

   public String getTitle() {
      return title;
   }

   public void setTitle(String title) {
      this.title = title;
   }

   public String getDirector() {
      return director;
   }

   public void setDirector(String director) {
      this.director = director;
   }

   public int getScore() {
      return score;
   }

   public void setScore(int score) {
      this.score = score;
   }

   public int getYear() {
      return year;
   }

   public void setYear(int year) {
      this.year = year;
   }

   @Override
   public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      Movie movie = (Movie) o;
      return getScore() == movie.getScore() && getYear() == movie.getYear() && getTitle().equals(movie.getTitle()) && getDirector().equals(movie.getDirector());
   }

   @Override
   public int hashCode() {
      return Objects.hash(getTitle(), getDirector(), getScore(), getYear());
   }

   @Override
   public String toString() {
      return
              "title='" + title + "\', year=" + year +
              ", director='" + director + "\', score=" + score ;
   }

}
